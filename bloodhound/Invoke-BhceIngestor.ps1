#Requires -Version 7.0
[CmdletBinding()]
param(
    # Diretorio onde esta o SharpHound.exe
    [Parameter(Mandatory)] [string]   $SharpHoundPath,

    # Arquivo de log
    [Parameter(Mandatory)] [string]   $LogFile,

    # Dominios a coletar (um zip por dominio)
    [string[]] $Domains = @("corp.local", "sub.corp.local"),

    # Metodos de coleta do SharpHound. DCOnly = somente consultas ao DC (LDAP), sem tocar hosts.
    [string]   $CollectionMethods = "DCOnly",

    # Caminho do script BloodHoundOperator.ps1 (carregado via dot-source)
    [string]   $BHOperatorScript = "C:\Tools\Scripts\BloodHoundOperator.ps1",

    # BHCE - arquivo contendo ID e KEY (formato: "ID: ..." / "KEY: ..." em linhas separadas)
    [string]   $BHCredentialFile = "C:\Tools\Scripts\.bhkey",

    # BHCE - endpoint da instancia
    [string]   $BHServer   = "srv-bhce.corp.local",
    [string]   $BHProtocol = "https",  # "https" (porta 443, TLS) ou "http" (porta 80, texto puro)
    [string]   $BHPort     = "443",

    # Limpa o GRAFO do BHCE antes do upload (apaga nos/arestas coletados; preserva Tier Zero/Owned).
    # ATENCAO: exige que a sessao tenha role Administrator no BHCE (conta Upload-Only recebe 403).
    [switch]   $ClearDatabase,

    # Segundos de espera APOS o clear, antes de iniciar os uploads. O pipe volta a 'idle'
    # imediatamente, mas o backend ainda finaliza a limpeza; subir cedo demais faz o BHCE
    # CANCELAR o upload (observado: 5s = cancela; 60s = ok). 120s da margem de seguranca.
    # So se aplica com -ClearDatabase.
    [int]      $PostClearWaitSeconds = 120
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR')] [string]$Level = 'INFO')
    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    $line | Tee-Object -FilePath $LogFile -Append | Out-Null
    Write-Host $line
}

# Espera o data pipe do BHCE voltar a 'idle' (limpeza/ingest terminados no backend).
# Retorna $true se ficou idle dentro do timeout; $false se estourou o tempo.
function Wait-BHPipeIdle {
    param(
        [int] $TimeoutSeconds = 300,
        [int] $PollSeconds    = 5
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    # pequena pausa inicial: o status pode ainda estar 'idle' do estado anterior
    # antes de a operacao recem-disparada mudar para 'analyzing'/'ingesting'.
    Start-Sleep -Seconds $PollSeconds
    do {
        try   { $status = (Get-BHData -PipeStatus).status }
        catch { $status = "unknown" }
        if ($status -eq 'idle') { return $true }
        Write-Log "  Pipe status: $status (aguardando idle)..."
        Start-Sleep -Seconds $PollSeconds
    } while ((Get-Date) -lt $deadline)
    return $false
}

# Espera um job de upload especifico (por ID) chegar a um status final.
# Status do BHCE: 2 = Complete ; 3 = Canceled ; outros = em processamento.
# Retorna o objeto do job no estado final, ou $null se estourar o timeout.
# Consulta a API direta (/api/v2/file-upload) porque Get-BHDataUpload nesta versao
# nao lista os jobs de forma confiavel.
function Wait-BHUploadJob {
    param(
        [Parameter(Mandatory)][int] $JobId,
        [int] $TimeoutSeconds = 600,
        [int] $PollSeconds    = 10
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Seconds $PollSeconds
        try {
            $todos = (Invoke-BHAPI -Method GET -Uri '/api/v2/file-upload?limit=25&skip=0').data
        } catch {
            Write-Log "  Falha ao consultar status do job ${JobId}: $($_.Exception.Message)" 'WARN'
            $todos = @()
        }
        $job = $todos | Where-Object { [int]$_.id -eq $JobId } | Select-Object -First 1
        if ($job -and $job.status -in @(2,3)) { return $job }
        $st = if ($job) { $job.status } else { 'desconhecido' }
        Write-Log "  Job ${JobId} em processamento (status=$st)..."
    } while ((Get-Date) -lt $deadline)
    return $null
}

try {
    # Garante a pasta do log
    $logDir = Split-Path -Parent $LogFile
    if ($logDir -and -not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    Write-Log "===== Inicio da execucao ====="

    # Registra sob qual identidade estamos rodando (na task, deve ser a gMSA)
    $whoAmI = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Log "Executando como: $whoAmI"

    # ---------- 1) Coleta com SharpHound ----------
    $sharpHound = Join-Path $SharpHoundPath "SharpHound.exe"
    if (-not (Test-Path $sharpHound)) { throw "SharpHound.exe nao encontrado em '$sharpHound'." }

    $outDir = Join-Path $SharpHoundPath "Coletas"
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    $zipsParaUpload = @()

    foreach ($domain in $Domains) {
        $zipName = ($domain -replace '\.', '_')   # corp.local -> corp_local
        Write-Log "Coletando dominio '$domain' (metodos=$CollectionMethods, zipfilename=$zipName)..."

        # Marca temporal para localizar o zip gerado por esta execucao
        $antes = Get-Date

        $saida = & $sharpHound `
            --collectionmethods $CollectionMethods `
            --domain $domain `
            --outputdirectory $outDir `
            --zipfilename $zipName 2>&1
        $rc = $LASTEXITCODE

        $saida | ForEach-Object { Write-Log "  [SharpHound] $_" }

        if ($rc -ne 0) {
            Write-Log "SharpHound retornou codigo $rc para '$domain'. Pulando upload deste dominio." 'ERROR'
            continue
        }

        # SharpHound prefixa timestamp no nome; pega o zip mais novo que casa com o nome
        $zip = Get-ChildItem -Path $outDir -Filter "*$zipName*.zip" |
               Where-Object { $_.LastWriteTime -ge $antes } |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1

        if ($zip) {
            Write-Log "Zip gerado: $($zip.FullName)"
            $zipsParaUpload += $zip.FullName
        } else {
            Write-Log "Nenhum zip encontrado para '$domain' apos a coleta." 'WARN'
        }
    }

    if (-not $zipsParaUpload) { throw "Nenhum zip foi gerado; nada para enviar ao BHCE." }

    # ---------- 2) Upload para o BHCE (BloodHoundOperator, exige PS7) ----------
    if (-not (Test-Path $BHOperatorScript)) { throw "BloodHoundOperator.ps1 nao encontrado em '$BHOperatorScript'." }
    . $BHOperatorScript
    Write-Log "BloodHoundOperator carregado (dot-source)."

    # Le ID e KEY do arquivo de credencial
    if (-not (Test-Path $BHCredentialFile)) { throw "Arquivo de credencial nao encontrado: $BHCredentialFile" }

    $BHTokenID       = $null
    $BHTokenKeyPlain = $null

    foreach ($linha in (Get-Content -LiteralPath $BHCredentialFile)) {
        $t = $linha.Trim()
        if     ($t -match '^\s*ID\s*:\s*(.+)$')  { $BHTokenID       = $Matches[1].Trim() }
        elseif ($t -match '^\s*KEY\s*:\s*(.+)$') { $BHTokenKeyPlain = $Matches[1].Trim() }
    }

    if ([string]::IsNullOrWhiteSpace($BHTokenID))       { throw "ID nao encontrado em $BHCredentialFile (esperado 'ID: ...')." }
    if ([string]::IsNullOrWhiteSpace($BHTokenKeyPlain)) { throw "KEY nao encontrada em $BHCredentialFile (esperado 'KEY: ...')." }

    $BHTokenKey = $BHTokenKeyPlain | ConvertTo-SecureString -AsPlainText -Force
    $BHTokenKeyPlain = $null   # limpa a variavel em claro da memoria o quanto antes

    Write-Log "Credencial BHCE carregada de $BHCredentialFile (ID=$BHTokenID)."

    New-BHSession -TokenID $BHTokenID -Token $BHTokenKey -Server $BHServer -Protocol $BHProtocol -Port $BHPort | Out-Null

    # New-BHSession NAO lanca excecao com token invalido: so emite WARNING e cria uma
    # sessao placeholder com campos 'tbd'. Precisamos confirmar que autenticou de fato,
    # senao o clear/upload rodam contra uma sessao invalida e o BHCE cancela os jobs
    # (sintoma: File Ingest = Canceled / 0 Files) enquanto o log diria "sucesso".
    $sess = Get-BHSession | Select-Object -First 1
    if (-not $sess -or $sess.Operator -in @($null, '', 'tbd')) {
        throw "Falha de autenticacao no BHCE: sessao invalida (Operator='$($sess.Operator)'). Verifique o token no $BHCredentialFile, o relogio da maquina (assinatura HMAC) e o endpoint $BHProtocol`://$BHServer`:$BHPort."
    }
    Write-Log "Sessao BHCE autenticada como '$($sess.Operator)' (Role=$($sess.Role)) em $BHProtocol`://$BHServer`:$BHPort."

    if ($ClearDatabase) {
        Write-Log "Limpando o grafo do BHCE via API (/api/v2/clear-database)..." 'WARN'
        # NAO usamos 'Clear-BHDatabase -GraphData AllData': nesta versao BETA o cmdlet
        # monta o payload errado (deleteCollectedGraphData=false) e nao apaga o grafo.
        # Chamamos a API direto com o payload correto, reusando a sessao autenticada.
        # Requer sessao com role Administrator (Upload-Only/Power User recebe 403).
        # Payload minimo: apaga TODO o grafo. NAO combina com deleteSourceKinds (proibido pela API).
        # Marcacoes manuais (Tier Zero / Owned) NAO sao apagadas por este payload.
        Invoke-BHAPI -Method POST -Uri '/api/v2/clear-database' -Body '{"deleteCollectedGraphData": true}' | Out-Null
        Write-Log "Requisicao de limpeza enviada. Aguardando o backend concluir..."

        if (Wait-BHPipeIdle -TimeoutSeconds 300 -PollSeconds 5) {
            Write-Log "Grafo limpo (pipe idle). Marcacoes manuais preservadas."
        } else {
            # Se a limpeza nao confirmou, NAO seguimos para o upload:
            # subir por cima de uma limpeza ainda em curso pode apagar os dados novos.
            throw "Timeout esperando a limpeza concluir (pipe nao ficou idle). Upload abortado para evitar corrida."
        }

        # IMPORTANTE: o pipe volta a 'idle' imediatamente apos o clear, mas o backend ainda
        # esta finalizando a limpeza do grafo. Iniciar o upload cedo demais faz o BHCE
        # CANCELAR o job (status 3, 0 files). Observado: upload 5s apos o clear = cancelado;
        # 60s = Complete. Por isso esperamos aqui antes de subir.
        if ($PostClearWaitSeconds -gt 0) {
            Write-Log "Aguardando $PostClearWaitSeconds s para o backend assentar apos a limpeza..."
            Start-Sleep -Seconds $PostClearWaitSeconds
        }
    }

    # Uploads SERIALIZADOS: enviar os zips em rajada faz o BHCE cancelar os jobs
    # (observado: dois uploads com ~1s de intervalo = ambos Canceled/0 files; com espera
    # entre eles = ambos Complete). Entao enviamos um por vez e esperamos cada job
    # chegar a status final antes do proximo.
    # Identificamos cada job novo pelo maior ID (sequencial/crescente no BHCE).
    Write-Log "Iniciando uploads serializados ($($zipsParaUpload.Count) arquivo(s))..."

    $resultados = @()

    foreach ($z in $zipsParaUpload) {
        # Maior ID existente imediatamente antes deste upload
        $maxIdAntes = 0
        try {
            $pre = (Invoke-BHAPI -Method GET -Uri '/api/v2/file-upload?limit=25&skip=0').data
            if ($pre) { $maxIdAntes = ($pre | Measure-Object -Property id -Maximum).Maximum }
        } catch {
            Write-Log "  Nao foi possivel ler jobs antes do upload: $($_.Exception.Message)" 'WARN'
        }

        Write-Log "Enviando: $z"
        Invoke-BHDataUpload $z    # caminho posicional, como validado manualmente
        Write-Log "Upload enviado. Aguardando o job (id > $maxIdAntes) concluir..."

        # Descobre o ID do job recem-criado (primeiro id > maxIdAntes)
        Start-Sleep -Seconds 3
        $novoId = $null
        try {
            $agora  = (Invoke-BHAPI -Method GET -Uri '/api/v2/file-upload?limit=25&skip=0').data
            $novoId = ($agora | Where-Object { [int]$_.id -gt $maxIdAntes } |
                       Sort-Object id | Select-Object -First 1).id
        } catch { }

        if (-not $novoId) {
            throw "Nao foi possivel identificar o job de upload criado para '$z'."
        }

        $job = Wait-BHUploadJob -JobId ([int]$novoId) -TimeoutSeconds 600 -PollSeconds 10
        if (-not $job) {
            throw "Timeout aguardando o job $novoId ('$z') concluir. Verifique a UI (File Ingest)."
        }
        if ($job.status -ne 2 -or [int]$job.total_files -eq 0) {
            Write-Log "Job com problema: id=$($job.id) status=$($job.status) total_files=$($job.total_files)" 'ERROR'
            throw "Upload de '$z' nao foi ingerido com sucesso (job $($job.id), status=$($job.status)). O grafo pode estar incompleto."
        }
        Write-Log "Ingest OK: id=$($job.id) status=Complete total_files=$($job.total_files)."
        $resultados += $job
    }

    Write-Log "Todos os $($resultados.Count) uploads foram ingeridos com sucesso."

    Write-Log "===== Execucao concluida com sucesso ====="
}
catch {
    Write-Log "FALHA: $($_.Exception.Message)" 'ERROR'
    Write-Log $_.ScriptStackTrace 'ERROR'
    exit 1
}

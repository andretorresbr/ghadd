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
    [string]   $BHProtocol = "http",   # "http" (porta 80, texto puro) ou "https"
    [string]   $BHPort     = "80",

    # Limpa o GRAFO do BHCE antes do upload (apaga nos/arestas coletados; preserva Tier Zero/Owned).
    # ATENCAO: exige que a sessao tenha role Administrator no BHCE (conta Upload-Only recebe 403).
    [switch]   $ClearDatabase
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
    $null = Get-BHSession
    Write-Log "Sessao BHCE criada ($BHProtocol`://$BHServer`:$BHPort)."

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
    }

    foreach ($z in $zipsParaUpload) {
        Write-Log "Enviando: $z"
        # Caminho passado posicionalmente, como validado manualmente (BHDataUpload $ZipFilePath).
        # BHDataUpload e alias de Invoke-BHDataUpload.
        Invoke-BHDataUpload $z
        Write-Log "Upload disparado para: $z"
    }

    # Espera o ingest dos zips terminar, para o log refletir conclusao real (nao so "disparado").
    Write-Log "Aguardando o BHCE processar os uploads..."
    if (Wait-BHPipeIdle -TimeoutSeconds 600 -PollSeconds 10) {
        Write-Log "Ingest concluido (pipe idle)."
    } else {
        Write-Log "Timeout aguardando o ingest concluir. Os uploads foram enviados; verifique a UI (File Ingest)." 'WARN'
    }

    Write-Log "===== Execucao concluida com sucesso ====="
}
catch {
    Write-Log "FALHA: $($_.Exception.Message)" 'ERROR'
    Write-Log $_.ScriptStackTrace 'ERROR'
    exit 1
}

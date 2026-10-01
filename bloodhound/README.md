# Invoke-BhceIngestor.ps1

Coleta os domínios do Active Directory com o **SharpHound** (modo `DCOnly`, apenas LDAP) e envia os resultados para uma instância **BloodHound CE (BHCE)**, opcionalmente limpando o grafo antes de cada carga. Projetado para rodar de forma agendada, sob uma **gMSA**, todo domingo às 20h.

## Visão geral do fluxo

A cada execução, o script:

1. Registra a identidade sob a qual está rodando (deve ser a gMSA).
2. Coleta cada domínio com `SharpHound.exe --collectionmethods DCOnly` (um `.zip` por domínio).
3. Carrega o módulo **BloodHoundOperator** via *dot-source*.
4. Lê `ID` e `KEY` do arquivo de credencial, abre uma sessão no BHCE e **confirma que autenticou** (aborta se a sessão vier inválida).
5. (Opcional, com `-ClearDatabase`) limpa o grafo via API, espera o *pipe* ficar `idle` e aguarda uma margem para o backend assentar.
6. Faz upload dos `.zip` **um por vez**, esperando cada job concluir, e valida o status final de cada ingest via API.

## Pré-requisitos

Estes pontos não são opcionais — cada um foi motivo de falha durante a implantação.

* **PowerShell 7** (`pwsh.exe`). O BloodHoundOperator exige PS7; o Windows PowerShell 5.1 (`powershell.exe`) **não** serve — em 5.1 a autenticação falha silenciosamente e a sessão fica com campos `tbd`. Caminho típico: `C:\Program Files\PowerShell\7\pwsh.exe`.
* **SharpHound.exe** em um diretório dedicado (ex.: `C:\Tools\sharphound`).
* **BloodHoundOperator.ps1** (projeto [SadProcessor/BloodHoundOperator](https://github.com/SadProcessor/BloodHoundOperator)) baixado localmente — **não** está na PowerShell Gallery; carrega-se por *dot-source*, não por `Import-Module`.
* **gMSA** (ex.: `corp\svc_coletorbhce$`) instalada e testável na máquina de coleta:

```powershell
Test-ADServiceAccount svc_coletorbhce   # deve retornar True
```

  A gMSA precisa do direito **"Log on as a batch job"** e **não** precisa de Domain Admin: `DCOnly` coleta tudo via LDAP como usuário autenticado comum.

* **Conta/token no BHCE.** O upload funciona com uma conta **Upload-Only**. Já a limpeza do grafo (`-ClearDatabase`) exige role **Administrator** no BHCE — uma conta Upload-Only recebe `403`. Escolha consciente de quem vai limpar (ver seção *Limpeza do grafo*).

## Arquivo de credencial (`.bhkey`)

O script lê o `TokenID` e a `Token Key` de um arquivo texto, **duas linhas rotuladas**:

```
ID: 00000000-0000-0000-0000-000000000000
KEY: <seu_token_key_do_bhce>
```

Crie o arquivo sem BOM e restrinja o acesso — a gMSA precisa apenas de **leitura**:

```powershell
$keyFile = "C:\Tools\Scripts\.bhkey"
[System.IO.File]::WriteAllText($keyFile, "ID: <id>`r`nKEY: <key>")

$acl = New-Object System.Security.AccessControl.FileSecurity
$acl.SetAccessRuleProtection($true, $false)   # remove herança
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("corp\svc_coletorbhce$","Read","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","Allow")))
Set-Acl $keyFile $acl
```

> **Segurança:** o token vive em texto puro no disco, protegido por ACL. Se a conta for Administrator no BHCE, trate o `.bhkey` como um segredo sensível e **rotacione o token periodicamente**.

## Parâmetros

|Parâmetro|Obrigatório|Descrição|
|-|-|-|
|`-SharpHoundPath`|sim|Diretório do `SharpHound.exe`. Os `.zip` vão para o subdiretório `Coletas`.|
|`-LogFile`|sim|Caminho do log. **Use um diretório onde a gMSA escreve** (ex.: `C:\Tools\sharphound\`), nunca um diretório só-leitura.|
|`-Domains`|não|Domínios a coletar. Padrão: `corp.local`, `sub.corp.local`.|
|`-CollectionMethods`|não|Métodos do SharpHound. Padrão: `DCOnly` (só LDAP, sem tocar hosts).|
|`-BHOperatorScript`|não|Caminho do `BloodHoundOperator.ps1`. Padrão: `C:\Tools\Scripts\BloodHoundOperator.ps1`.|
|`-BHCredentialFile`|não|Caminho do `.bhkey`. Padrão: `C:\Tools\Scripts\.bhkey`.|
|`-BHServer` / `-BHProtocol` / `-BHPort`|não|Endpoint do BHCE. Padrão: `srv-bhce.corp.local` / `https` / `443`.|
|`-ClearDatabase`|não|Limpa o grafo antes do upload. **Exige sessão Administrator no BHCE.**|
|`-PostClearWaitSeconds`|não|Segundos de espera após o clear, antes dos uploads. Padrão: `120`. Só se aplica com `-ClearDatabase`.|

## Limpeza do grafo (`-ClearDatabase`)

A limpeza é feita chamando a API do BHCE diretamente:

```
POST /api/v2/clear-database   { "deleteCollectedGraphData": true }
```

> **Por que não `Clear-BHDatabase`?** Na versão BETA do BloodHoundOperator, `Clear-BHDatabase -GraphData AllData` monta o payload errado (`deleteCollectedGraphData: false`) e **não apaga o grafo**. Por isso o script usa `Invoke-BHAPI` com o payload correto.

O payload envia **apenas** `deleteCollectedGraphData: true` — isso apaga o grafo coletado, mas **preserva** marcações manuais (Tier Zero / Owned).

> **Espera obrigatória após o clear.** O `Get-BHData -PipeStatus` volta a `idle` quase imediatamente após o clear, mas o backend ainda está finalizando a limpeza do grafo. Se o upload começa cedo demais, o BHCE **cancela** o job (status 3, `0 files`). Observado: upload ~5s após o clear = Cancelado; ~60s = Complete. Por isso o script espera `-PostClearWaitSeconds` (padrão 120s) após o clear antes de subir. **Não confie apenas no `pipe idle`.**

> **Nota sobre acúmulo:** reenviar a coleta atualiza os nós existentes (mesmos objectIDs) em vez de duplicar. A limpeza só é necessária para remover objetos que **deixaram de existir** no AD. Se isso não for requisito, rode **sem** `-ClearDatabase` e mantenha a conta como Upload-Only (menor privilégio).

## Upload e verificação de status

Os uploads são feitos **um por vez** (serializados): após enviar cada `.zip`, o script espera aquele job concluir antes de enviar o próximo. Disparar vários uploads em rajada pode fazer o BHCE cancelá-los.

A verificação de status consulta a **API diretamente** (`GET /api/v2/file-upload`) em vez do cmdlet `Get-BHDataUpload`, porque nesta versão o cmdlet não lista os jobs recentes de forma confiável (quebra com jobs de `status_message` vazio, retornando apenas um job antigo).

Cada job é identificado pelo **ID** (sequencial e crescente) e aguardado até atingir um status final. Códigos de status do BHCE observados:

|`status`|Significado|
|-|-|
|`2`|Complete (sucesso)|
|`3`|Canceled|
|`6`|Em processamento (analyzing/ingesting)|

O script trata qualquer status diferente de `2` e `3` como "ainda processando" e continua aguardando. Só considera sucesso quando o job chega a `status = 2` com `total_files > 0`; caso contrário, falha com erro explícito (evitando o falso "sucesso" em que o log dizia OK mas a UI mostrava Canceled).

## Execução manual (teste)

```powershell
& "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass `
  -File "C:\Tools\Scripts\Invoke-BhceIngestor.ps1" `
  -SharpHoundPath 'C:\Tools\sharphound' `
  -LogFile 'C:\Tools\sharphound\Invoke-BhceIngestor_log.txt' `
  -ClearDatabase
```

> Rode sempre em **pwsh 7**, nunca no PowerShell 5.1 (a autenticação no BHCE falha silenciosamente em 5.1).

> Para testar **sob a identidade da gMSA**, rode via PsExec (`-u corp\svc_coletorbhce$`) ou dispare a própria tarefa com `Start-ScheduledTask`. **Não** rode como seu usuário admin dentro de `Coletas`: isso recria o cache `.bin` do SharpHound com outro dono e quebra a próxima execução da gMSA (`Access to the path ... is denied`).

## Agendamento (todo domingo às 20h)

Registra a tarefa sob a gMSA, com **PowerShell 7**.

```powershell
# This script creates a scheduled task to run the BHCE ingestor every Sunday at 8pm
# It uses the ScheduledTask module, which is available on Windows Server 2012 and newer.

# --- Task Configuration Variables ---
$TaskName = "Ingest and load BHCE information"
$TaskDescription = "Runs BloodHound CE ingestor and loads it into BHCE"
$ScriptPath = "C:\Tools\Scripts\Invoke-BhceIngestor.ps1" # <--- IMPORTANT: Update this path if your script is in a different location
# --- Action to be performed by the task ---
$InnerCommand = "& '$ScriptPath' -SharpHoundPath 'C:\Tools\sharphound' -LogFile 'C:\Tools\sharphound\Invoke-BhceIngestor_log.txt' -ClearDatabase"
$TaskAction = New-ScheduledTaskAction -Execute "C:\Program Files\PowerShell\7\pwsh.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"$InnerCommand`""
# --- Trigger for the task ---
# This creates a weekly trigger that runs every Sunday 8pm.
$TaskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 20:00
# --- Principal (User Account) for the task ---
# This sets the task to run with System privileges, whether a user is logged on or not.
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "corp\svc_coletorbhce$" -LogonType Password -RunLevel Highest

# --- Register the scheduled task ---
try {
    Write-Host "Registering scheduled task '$TaskName'..."
    Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -Principal $TaskPrincipal -TaskName $TaskName -Description $TaskDescription -Force
    Write-Host "Scheduled task '$TaskName' successfully registered." -ForegroundColor Green
}
catch {
    Write-Error "Failed to register the scheduled task. Ensure you are running PowerShell with Administrator privileges."
}
```

> **`-Command` vs `-File`:** com `-File`, o Task Scheduler quebra o parsing dos argumentos entre aspas simples e a tarefa falha com `LastTaskResult=1` sem gerar log. Usar `-Command` com o *call operator* (`&`) resolve, porque o pwsh avalia a string como código.

> **Endpoint HTTPS:** o script usa `https` / `443` por padrão, então o comando acima não precisa passar `-BHProtocol`/`-BHPort`. Passe esses parâmetros apenas se o seu BHCE usar outro endpoint. Atenção: `-BHServer` recebe **somente o hostname** (`srv-bhce.corp.local`), sem `https://` embutido — o protocolo vai em `-BHProtocol`.

## Validação pós-agendamento

Dispare sob demanda em vez de esperar o domingo. Com `-ClearDatabase` o ciclo leva alguns minutos (espera pós-clear + ingest serializado), então aguarde o suficiente:

```powershell
Start-ScheduledTask -TaskName "Ingest and load BHCE information"
Start-Sleep -Seconds 300
Get-ScheduledTaskInfo -TaskName "Ingest and load BHCE information" | Select-Object LastRunTime, LastTaskResult
Get-Content "C:\Tools\sharphound\Invoke-BhceIngestor_log.txt" -Tail 20
```

* `LastTaskResult = 0` → sucesso.
* O log deve mostrar `Sessao BHCE autenticada como 'bhce_coletor'`, um `Ingest OK: id=... status=Complete total_files=...` por domínio, e terminar em `===== Execucao concluida com sucesso =====`.

Confirme também que o grafo repopulou:

```powershell
# em pwsh 7, com sessão aberta:
Get-BHData -ListDomain -Collected   # deve listar os domínios com collected = True
```

## Troubleshooting

|Sintoma|Causa provável|Correção|
|-|-|-|
|Sessão com campos `tbd` / `Invalid Session Token`|Rodando em PowerShell 5.1|Use **pwsh 7**. O BloodHoundOperator não autentica em 5.1.|
|`LastTaskResult=1`, sem log|Ação com `-File` (parsing quebrado) ou `-LogFile` em diretório sem escrita da gMSA|Use `-Command` (acima) e log em `C:\Tools\sharphound\`|
|Jobs entram como **Canceled** / `0 files`|Upload disparado cedo demais após o clear (backend ainda assentando)|Espera pós-clear (`-PostClearWaitSeconds`, padrão 120s). Já tratado no script.|
|Vários uploads em rajada cancelam|Uploads concorrentes|Uploads serializados (um por vez). Já tratado no script.|
|`403 - not authorized` na limpeza|Conta BHCE é Upload-Only / Power User|Use conta com role **Administrator** para o clear|
|`Clear-BHDatabase` não apaga o grafo|Bug da BETA (`deleteCollectedGraphData:false`)|Já contornado: o script usa `Invoke-BHAPI`|
|`Get-BHDataUpload` só retorna um job antigo|Cmdlet quebra com jobs de `status_message` vazio|Verificação usa a API direta (`/api/v2/file-upload`). Já tratado no script.|
|`Access to the path '...bin' is denied`|Cache do SharpHound com dono de outra conta|Apague `Coletas` e deixe a gMSA recriá-lo; não rode como admin ali|
|`module 'BloodHoundOperator' was not loaded`|Tentou `Import-Module`|Carregue por *dot-source*: `. C:\Tools\Scripts\BloodHoundOperator.ps1`|

## Notas de segurança / tiering

* `DCOnly` coleta só via LDAP: a gMSA **não** precisa (e não deve ter) Domain Admin nem admin local nos hosts.
* Mantenha `C:\Tools\Scripts\` como **leitura** para a gMSA (protege `.bhkey` e `BloodHoundOperator.ps1`); a gMSA só escreve em `Coletas` e no diretório de log.
* Se usar conta Admin no BHCE para o clear, é o único ponto administrativo da automação — rotacione o token e proteja o `.bhkey`.

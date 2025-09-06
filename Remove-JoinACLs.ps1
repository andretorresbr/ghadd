# Author: Andre Torres (https://github.com/andretorresbr/ghadd/)

 # Importa o módulo do Active Directory (AD)
Import-Module ActiveDirectory

# Obtém a data e hora atual no formato desejado
$dataAtual = Get-Date -Format "dd-MM-yyyy_HHmmss"

# Define o nome do arquivo com base na data e hora atual
$nomeArquivo = ".\Remove-JoinACLs_Log_$dataAtual.txt"

# Armazena os logs
Start-Transcript -Path $nomeArquivo

# Configura a conta cujas ACLs serão removidas (conta de join no domínio)
$creatorAccount = "CORP\andre.torres" # => ALTERAR PARA CONFIGURAR A CONTA DE JOIN DO DOMÍNIO

# Obtém a lista de computadores do domínio
$computers = Get-ADComputer -Filter *

foreach ($computer in $computers)
{
    # Verifica as ACLs do objeto de computador
    $acl = Get-ACL "AD:$($computer.DistinguishedName)"

    # Se houver computador cujo owner é a conta de join, muda para Domain Admins
    if ($acl.Owner -eq $creatorAccount)
    {
        Write-Host "*** Alterando o owner do computador" $computer.DNSHostName "de" $creatorAccount "para Domain Admins"
        $acl.SetOwner([System.Security.Principal.NTAccount]"Domain Admins")
    }

    # Filtra as entradas de ACL associadas ao usuário que ingressou o computador no domínio
    $entriesToRemove = $acl.Access | Where-Object { $_.IdentityReference -eq $creatorAccount }
    
    # Caso existam entradas a ser removidas na presente máquina
    if ($entriesToRemove)
    {
        Write-Host "*** Limpando as seguintes permissoes do usuario"$creatorAccount "no computador" $computer.DNSHostName
        $entriesToRemove

        # Remove as DACLs perigosas associadas ao criador do objeto (usuário que ingressou o computador)
        foreach ($entry in $entriesToRemove) 
        {
            $acl.RemoveAccessRule($entry)
        }
        # Aplica as mudanças de volta no objeto de computador no AD
        Set-ACL -Path "AD:$($computer.DistinguishedName)" -AclObject $acl
    }
}


Stop-Transcript

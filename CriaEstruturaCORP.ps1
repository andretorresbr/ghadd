# 0.1 Senha padrão dos usuários Tier2: Senh@Usuario
$senha_usuario_tier2 = ConvertTo-SecureString -String "Senh@Usuariopc" -AsPlainText -Force
# 0.2 Senha padrão dos administradores Tier1: Senh@Admin
$senha_usuario_tier1 = ConvertTo-SecureString -String "Senh@ServerAdmin" -AsPlainText -Force
# 0.3 Senha padrão dos administradores Tier0: Senh@DomainAdmin
$senha_usuario_tier0 = ConvertTo-SecureString -String "Senh@DomainAdmin" -AsPlainText -Force


# 1 Criação de OUs

# 1.1 Criação na raiz
New-ADOrganizationalUnit -Name "Tier0" -Path "DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Tier1" -Path "DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Tier2" -Path "DC=CORP,DC=LOCAL"

# 1.2 Criação na Tier0
New-ADOrganizationalUnit -Name "Usuarios" -Path "OU=Tier0,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Grupos" -Path "OU=Tier0,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Papeis" -Path "OU=Tier0,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Servidores" -Path "OU=Tier0,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Contas de Servico" -Path "OU=Tier0,DC=CORP,DC=LOCAL"

# 1.3 Criação na Tier1
New-ADOrganizationalUnit -Name "Usuarios" -Path "OU=Tier1,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Grupos" -Path "OU=Tier1,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Servidores" -Path "OU=Tier1,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Papeis" -Path "OU=Tier1,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Contas de Servico" -Path "OU=Tier1,DC=CORP,DC=LOCAL"

# 1.4 Criação na Tier2
New-ADOrganizationalUnit -Name "Usuarios" -Path "OU=Tier2,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Grupos" -Path "OU=Tier2,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Estacoes" -Path "OU=Tier2,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Papeis" -Path "OU=Tier2,DC=CORP,DC=LOCAL"
New-ADOrganizationalUnit -Name "Contas de Servico" -Path "OU=Tier2,DC=CORP,DC=LOCAL"

# 1.4.1 Criação na Tier2/Estacoes
#New-ADOrganizationalUnit -Name "TI" -Path "OU=Estacoes,OU=Tier2,DC=CORP,DC=LOCAL"
#New-ADOrganizationalUnit -Name "Financeiro" -Path "OU=Estacoes,OU=Tier2,DC=CORP,DC=LOCAL"
#New-ADOrganizationalUnit -Name "Marketing" -Path "OU=Estacoes,OU=Tier2,DC=CORP,DC=LOCAL"
#New-ADOrganizationalUnit -Name "Presidencia" -Path "OU=Estacoes,OU=Tier2,DC=CORP,DC=LOCAL"
#New-ADOrganizationalUnit -Name "Recursos Humanos" -Path "OU=Estacoes,OU=Tier2,DC=CORP,DC=LOCAL"
#New-ADOrganizationalUnit -Name "Vendas" -Path "OU=Estacoes,OU=Tier2,DC=CORP,DC=LOCAL"

# 2 Criação de grupos

# 2.1 Criação na Tier2
New-ADGroup -Name "TI - Helpdesk" -SamAccountName "TI - Helpdesk" -GroupCategory Security -GroupScope Global -DisplayName "TI - Helpdesk" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Membros da area de atendimento ao usuario (Helpdesk)"
New-ADGroup -Name "TI" -SamAccountName "TI" -GroupCategory Security -GroupScope Global -DisplayName "TI" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Funcionarios da area de TI"
New-ADGroup -Name "Recursos Humanos" -SamAccountName "Recursos Humanos" -GroupCategory Security -GroupScope Global -DisplayName "Recursos Humanos" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Funcionarios da area de Recursos Humanos (RH)"
New-ADGroup -Name "Financeiro" -SamAccountName "Financeiro" -GroupCategory Security -GroupScope Global -DisplayName "Financeiro" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Funcionarios da area de financas"
New-ADGroup -Name "Marketing" -SamAccountName "Marketing" -GroupCategory Security -GroupScope Global -DisplayName "Marketing" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Funcionarios da area de marketing"
New-ADGroup -Name "Vendas" -SamAccountName "Vendas" -GroupCategory Security -GroupScope Global -DisplayName "Vendas" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Funcionarios da area de vendas"
New-ADGroup -Name "Presidencia" -SamAccountName "Presidencia" -GroupCategory Security -GroupScope Global -DisplayName "Presidencia" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Funcionarios da presidencia"
New-ADGroup -Name "T2 Users" -SamAccountName "T2 Users" -GroupCategory Security -GroupScope Global -DisplayName "T2 Users" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Todos os funcionarios da organizacao"
New-ADGroup -Name "T2 Estacoes" -SamAccountName "T2 Estacoes" -GroupCategory Security -GroupScope Global -DisplayName "T2 Estacoes" -Path "OU=Grupos,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Todas as estacoes de trabalho da Tier 2"

# 2.2 Criacão na Tier1
New-ADGroup -Name "T1 Admins" -SamAccountName "T1 Admins" -GroupCategory Security -GroupScope Global -DisplayName "T1 Admins" -Path "OU=Grupos,OU=Tier1,DC=CORP,DC=LOCAL" -Description "Administradores da Tier 1"
New-ADGroup -Name "T1 Users" -SamAccountName "T1 Users" -GroupCategory Security -GroupScope Global -DisplayName "T1 Users" -Path "OU=Grupos,OU=Tier1,DC=CORP,DC=LOCAL" -Description "Todos os usuarios da Tier 1"
New-ADGroup -Name "T1 Servers" -SamAccountName "T1 Servers" -GroupCategory Security -GroupScope Global -DisplayName "T1 Servers" -Path "OU=Grupos,OU=Tier1,DC=CORP,DC=LOCAL" -Description "Todos os servidores da Tier 1"

# 2.3 Criacão na Tier0
New-ADGroup -Name "T0 Admins" -SamAccountName "T0 Admins" -GroupCategory Security -GroupScope Global -DisplayName "T0 Admins" -Path "OU=Grupos,OU=Tier0,DC=CORP,DC=LOCAL" -Description "Administradores da Tier 0"
New-ADGroup -Name "T0 Users" -SamAccountName "T0 Users" -GroupCategory Security -GroupScope Global -DisplayName "T0 Users" -Path "OU=Grupos,OU=Tier0,DC=CORP,DC=LOCAL" -Description "Todos os usuarios da Tier 0"
New-ADGroup -Name "T0 Servers" -SamAccountName "T0 Servers" -GroupCategory Security -GroupScope Global -DisplayName "T0 Servers" -Path "OU=Grupos,OU=Tier0,DC=CORP,DC=LOCAL" -Description "Todos os servidores da Tier 0"
New-ADGroup -Name "PAW Estacoes" -SamAccountName "PAW Estacoes" -GroupCategory Security -GroupScope Global -DisplayName "PAW Estacoes" -Path "OU=Grupos,OU=Tier0,DC=CORP,DC=LOCAL" -Description "Estacoes de trabalho privilegiadas - PAW"

# 2.4 Criacão dos grupos de papeis (Roles)
New-ADGroup -Name "Administrar estacoes de trabalho - Tier 2" -SamAccountName "Administrar estacoes de trabalho - Tier 2" -GroupCategory Security -GroupScope Global -DisplayName "Administrar estacoes de trabalho - Tier 2" -Path "OU=Papeis,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Este papel permite ao membro administrar as estacoes de trabalho (Tier2)"
New-ADGroup -Name "Acessar os recursos de venda" -SamAccountName "Acessar os recursos de venda" -GroupCategory Security -GroupScope Global -DisplayName "Acessar os recursos de venda" -Path "OU=Papeis,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Este papel permite ao membro acessar os recursos de venda"
New-ADGroup -Name "Acessar os recursos da presidencia" -SamAccountName "Acessar os recursos da presidencia" -GroupCategory Security -GroupScope Global -DisplayName "Acessar os recursos da presidencia" -Path "OU=Papeis,OU=Tier2,DC=CORP,DC=LOCAL" -Description "Este papel permite ao membro acessar os recursos da presidencia"
New-ADGroup -Name "Administrar todos os servidores - Tier 1" -SamAccountName "Administrar todos os servidores - Tier 1" -GroupCategory Security -GroupScope Global -DisplayName "Administrar todos os servidores - Tier 1" -Path "OU=Papeis,OU=Tier1,DC=CORP,DC=LOCAL" -Description "Este papel permite ao membro administrar todos os servidores (Tier1)"
New-ADGroup -Name "Administrar o dominio CORP.LOCAL" -SamAccountName "Administrar o dominio CORP.LOCAL" -GroupCategory Security -GroupScope Global -DisplayName "Administrar o dominio CORP.LOCAL" -Path "OU=Papeis,OU=Tier0,DC=CORP,DC=LOCAL" -Description "Este papel permite ao membro administrar o dominio CORP.LOCAL (Tier0)"


# 3 Criacao dos usuarios

# 3.1 Criacao na Tier2
New-ADuser -Name "Andre Torres" -GivenName "Andre" -Surname "Torres" -DisplayName "Andre Torres" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "andre.torres@CORP.LOCAL" -SamAccountName "andre.torres" -Description "Atuacao: TI" -PasswordNeverExpires $true
New-ADuser -Name "Carlos Eduardo" -GivenName "Carlos" -Surname "Eduardo" -DisplayName "Carlos Eduardo" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "carlos.eduardo@CORP.LOCAL" -SamAccountName "carlos.eduardo" -Description "Atuacao: Financeiro" -PasswordNeverExpires $true
New-ADuser -Name "Flavio Silva" -GivenName "Flavio" -Surname "Silva" -DisplayName "Flavio Silva" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "flavio.silva@CORP.LOCAL" -SamAccountName "flavio.silva" -Description "Atuacao: Financeiro" -PasswordNeverExpires $true
New-ADuser -Name "Vinicius Santos" -GivenName "Vinicius" -Surname "Santos" -DisplayName "Vinicius Santos" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "vinicius.santos@CORP.LOCAL" -SamAccountName "vinicius.santos" -Description "Atuacao: Financeiro" -PasswordNeverExpires $true
New-ADuser -Name "Roberto Carvalho" -GivenName "Roberto" -Surname "Carvalho" -DisplayName "Roberto Carvalho" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "roberto.carvalho@CORP.LOCAL" -SamAccountName "roberto.carvalho" -Description "Atuacao: Marketing" -PasswordNeverExpires $true
New-ADuser -Name "Daniel Botelho" -GivenName "Daniel" -Surname "Botelho" -DisplayName "Daniel Botelho" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "daniel.botelho@CORP.LOCAL" -SamAccountName "daniel.botelho" -Description "Atuacao: Marketing" -PasswordNeverExpires $true
New-ADuser -Name "Amanda Hartt" -GivenName "Amanda" -Surname "Hartt" -DisplayName "Amanda Hartt" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "amanda.hartt@CORP.LOCAL" -SamAccountName "amanda.hartt" -Description "Atuacao: Marketing" -PasswordNeverExpires $true
New-ADuser -Name "Denilson Soares" -GivenName "Denilson" -Surname "Soares" -DisplayName "Denilson Soares" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "denilson.soares@CORP.LOCAL" -SamAccountName "denilson.soares" -Description "Atuacao: Presidencia" -PasswordNeverExpires $true
New-ADuser -Name "Arthur Gabardo" -GivenName "Arthur" -Surname "Gabardo" -DisplayName "Arthur Gabardo" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "arthur.gabardo@CORP.LOCAL" -SamAccountName "arthur.gabardo" -Description "Atuacao: Presidencia" -PasswordNeverExpires $true
New-ADuser -Name "Helena Almeida" -GivenName "Helena" -Surname "Almeida" -DisplayName "Helena Almeida" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "helena.almeida@CORP.LOCAL" -SamAccountName "helena.almeida" -Description "Atuacao: Presidencia" -PasswordNeverExpires $true
New-ADuser -Name "Miguel Azevedo" -GivenName "Miguel" -Surname "Azevedo" -DisplayName "Miguel Azevedo" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "miguel.azevedo@CORP.LOCAL" -SamAccountName "miguel.azevedo" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Samuel Braga" -GivenName "Samuel" -Surname "Braga" -DisplayName "Samuel Braga" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "samuel.braga@CORP.LOCAL" -SamAccountName "samuel.braga" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Gustavo Barros" -GivenName "Gustavo" -Surname "Barros" -DisplayName "Gustavo Barros" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "gustavo.barros@CORP.LOCAL" -SamAccountName "gustavo.barros" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Felipe Brasil" -GivenName "Felipe" -Surname "Brasil" -DisplayName "Felipe Brasil" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "felipe.brasil@CORP.LOCAL" -SamAccountName "felipe.brasil" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Joao Campos" -GivenName "Joao" -Surname "Campos" -DisplayName "Joao Campos" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "joao.campos@CORP.LOCAL" -SamAccountName "joao.campos" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Vitor Cardoso" -GivenName "Vitor" -Surname "Cardoso" -DisplayName "Vitor Cardoso" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "vitor.cardoso@CORP.LOCAL" -SamAccountName "vitor.cardoso" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Guilherme Correia" -GivenName "Guilherme" -Surname "Correia" -DisplayName "Guilherme Correia" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "guilherme.correia@CORP.LOCAL" -SamAccountName "guilherme.correia" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Leonardo Castro" -GivenName "Leonardo" -Surname "Castro" -DisplayName "Leonardo Castro" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "leonardo.castro@CORP.LOCAL" -SamAccountName "leonardo.castro" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Henrique Macedo" -GivenName "Henrique" -Surname "Macedo" -DisplayName "Henrique Macedo" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "henrique.macedo@CORP.LOCAL" -SamAccountName "henrique.macedo" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Livia Ribeiro" -GivenName "Livia" -Surname "Ribeiro" -DisplayName "Livia Ribeiro" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "livia.ribeiro@CORP.LOCAL" -SamAccountName "livia.ribeiro" -Description "Atuacao: Vendas" -PasswordNeverExpires $true
New-ADuser -Name "Rebeca Siqueira" -GivenName "Rebeca" -Surname "Siqueira" -DisplayName "Rebeca Siqueira" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "rebeca.siqueira@CORP.LOCAL" -SamAccountName "rebeca.siqueira" -Description "Atuacao: Recursos Humanos" -PasswordNeverExpires $true
New-ADuser -Name "Leticia Souza" -GivenName "Leticia" -Surname "Souza" -DisplayName "Leticia Souza" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "leticia.souza@CORP.LOCAL" -SamAccountName "leticia.souza" -Description "Atuacao: Recursos Humanos" -PasswordNeverExpires $true
New-ADuser -Name "Isac Teixeira" -GivenName "Isac" -Surname "Teixeira" -DisplayName "Isac Teixeira" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "isac.teixeira@CORP.LOCAL" -SamAccountName "isac.teixeira" -Description "Atuacao: TI" -PasswordNeverExpires $true
New-ADuser -Name "Rodrigo Matos" -GivenName "Rodrigo" -Surname "Matos" -DisplayName "Rodrigo Matos" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "rodrigo.matos@CORP.LOCAL" -SamAccountName "rodrigo.matos" -Description "Atuacao: TI" -PasswordNeverExpires $true
New-ADuser -Name "Help Desk1" -GivenName "Help" -Surname "Desk1" -DisplayName "Help Desk1" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "help.desk1@CORP.LOCAL" -SamAccountName "help.desk1" -Description "Atuacao: TI - Helpdesk" -PasswordNeverExpires $true
New-ADuser -Name "Help Desk2" -GivenName "Help" -Surname "Desk2" -DisplayName "Help Desk2" -AccountPassword $senha_usuario_tier2 -Path "OU=Usuarios,OU=Tier2,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "help.desk2@CORP.LOCAL" -SamAccountName "help.desk2" -Description "Atuacao: TI - Helpdesk" -PasswordNeverExpires $true

# 3.2 Criacao na Tier1
New-ADuser -Name "Andre Torres (T1 Admin)" -GivenName "Andre" -Surname "Torres" -DisplayName "Andre Torres (T1 Admin)" -AccountPassword $senha_usuario_tier1 -Path "OU=Usuarios,OU=Tier1,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "andre.torres_a@CORP.LOCAL" -SamAccountName "andre.torres_a" -Description "Administrador Tier 1" -PasswordNeverExpires $true
New-ADuser -Name "Isac Teixeira (T1 Admin)" -GivenName "Isac" -Surname "Teixeira" -DisplayName "Isac Teixeira (T1 Admin)" -AccountPassword $senha_usuario_tier1 -Path "OU=Usuarios,OU=Tier1,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "isac.teixeira_a@CORP.LOCAL" -SamAccountName "isac.teixeira_a" -Description "Administrador Tier 1" -PasswordNeverExpires $true
New-ADuser -Name "Rodrigo Matos (T1 Admin)" -GivenName "Rodrigo" -Surname "Matos" -DisplayName "Rodrigo Matos (T1 Admin)" -AccountPassword $senha_usuario_tier1 -Path "OU=Usuarios,OU=Tier1,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "rodrigo.matos_a@CORP.LOCAL" -SamAccountName "rodrigo.matos_a" -Description "Administrador Tier 1" -PasswordNeverExpires $true

# 3.3 Criacao na Tier0
New-ADuser -Name "Andre Torres (T0 Admin)" -GivenName "Andre" -Surname "Torres" -DisplayName "Andre Torres (T0 Admin)" -AccountPassword $senha_usuario_tier0 -Path "OU=Usuarios,OU=Tier0,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "andre.torres_da@CORP.LOCAL" -SamAccountName "andre.torres_da" -Description "Administrador Tier 0" -PasswordNeverExpires $true
New-ADuser -Name "Rodrigo Matos (T0 Admin)" -GivenName "Rodrigo" -Surname "Matos" -DisplayName "Rodrigo Matos (T0 Admin)" -AccountPassword $senha_usuario_tier0 -Path "OU=Usuarios,OU=Tier0,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "rodrigo.matos_da@CORP.LOCAL" -SamAccountName "rodrigo.matos_da" -Description "Administrador Tier 0" -PasswordNeverExpires $true
New-ADuser -Name "Break the glass (T0 Admin)" -GivenName "Break" -Surname "the Glass" -DisplayName "Break the glass (T0 Admin)" -AccountPassword $senha_usuario_tier0 -Path "OU=Usuarios,OU=Tier0,DC=CORP,DC=LOCAL" -Enabled $true -UserPrincipalName "breaktheglass_da@CORP.LOCAL" -SamAccountName "breaktheglass_da" -Description "Administrador break the glass Tier 0" -PasswordNeverExpires $true


# 4 Insercao dos usuarios nos grupos

# 4.1 Grupos Tier2
Add-ADGroupMember -Identity "TI" -Members "andre.torres"
Add-ADGroupMember -Identity "Financeiro" -Members "carlos.eduardo"
Add-ADGroupMember -Identity "Financeiro" -Members "flavio.silva"
Add-ADGroupMember -Identity "Financeiro" -Members "vinicius.santos"
Add-ADGroupMember -Identity "Marketing" -Members "roberto.carvalho"
Add-ADGroupMember -Identity "Marketing" -Members "daniel.botelho"
Add-ADGroupMember -Identity "Marketing" -Members "amanda.hartt"
Add-ADGroupMember -Identity "Presidencia" -Members "denilson.soares"
Add-ADGroupMember -Identity "Presidencia" -Members "arthur.gabardo"
Add-ADGroupMember -Identity "Presidencia" -Members "helena.almeida"
Add-ADGroupMember -Identity "Vendas" -Members "miguel.azevedo"
Add-ADGroupMember -Identity "Vendas" -Members "samuel.braga"
Add-ADGroupMember -Identity "Vendas" -Members "gustavo.barros"
Add-ADGroupMember -Identity "Vendas" -Members "felipe.brasil"
Add-ADGroupMember -Identity "Vendas" -Members "joao.campos"
Add-ADGroupMember -Identity "Vendas" -Members "vitor.cardoso"
Add-ADGroupMember -Identity "Vendas" -Members "guilherme.correia"
Add-ADGroupMember -Identity "Vendas" -Members "leonardo.castro"
Add-ADGroupMember -Identity "Vendas" -Members "henrique.macedo"
Add-ADGroupMember -Identity "Vendas" -Members "livia.ribeiro"
Add-ADGroupMember -Identity "Recursos Humanos" -Members "rebeca.siqueira"
Add-ADGroupMember -Identity "Recursos Humanos" -Members "leticia.souza"
Add-ADGroupMember -Identity "TI" -Members "isac.teixeira"
Add-ADGroupMember -Identity "TI" -Members "rodrigo.matos"
Add-ADGroupMember -Identity "TI - Helpdesk" -Members "help.desk1"
Add-ADGroupMember -Identity "TI - Helpdesk" -Members "help.desk2"
Add-ADGroupMember -Identity "Administrar estacoes de trabalho - Tier 2" -Members "TI - Helpdesk"
Add-ADGroupMember -Identity "Acessar os recursos de venda" -Members "Vendas"
Add-ADGroupMember -Identity "Acessar os recursos da presidencia" -Members "Presidencia"
Add-ADGroupMember -Identity "T2 Users" -Members "TI"
Add-ADGroupMember -Identity "T2 Users" -Members "Financeiro"
Add-ADGroupMember -Identity "T2 Users" -Members "Marketing"
Add-ADGroupMember -Identity "T2 Users" -Members "Presidencia"
Add-ADGroupMember -Identity "T2 Users" -Members "Vendas"
Add-ADGroupMember -Identity "T2 Users" -Members "Recursos Humanos"
Add-ADGroupMember -Identity "T2 Users" -Members "TI - Helpdesk"

# 4.2 Grupos Tier1
Add-ADGroupMember -Identity "T1 Admins" -Members "andre.torres_a"
Add-ADGroupMember -Identity "T1 Admins" -Members "isac.teixeira_a"
Add-ADGroupMember -Identity "T1 Admins" -Members "rodrigo.matos_a"
Add-ADGroupMember -Identity "T1 Users" -Members "andre.torres_a"
Add-ADGroupMember -Identity "T1 Users" -Members "isac.teixeira_a"
Add-ADGroupMember -Identity "T1 Users" -Members "rodrigo.matos_a"
Add-ADGroupMember -Identity "Administrar todos os servidores - Tier 1" -Members "T1 Admins"

# 4.3 Grupos Tier0
Add-ADGroupMember -Identity "T0 Admins" -Members "andre.torres_da"
Add-ADGroupMember -Identity "T0 Admins" -Members "rodrigo.matos_da"
Add-ADGroupMember -Identity "T0 Users" -Members "andre.torres_da"
Add-ADGroupMember -Identity "T0 Users" -Members "rodrigo.matos_da"
Add-ADGroupMember -Identity "Administrar o dominio CORP.LOCAL" -Members "T0 Admins"
Add-ADGroupMember -Identity "Domain Admins" -Members "Administrar o dominio CORP.LOCAL"
Add-ADGroupMember -Identity "Domain Admins" -Members "breaktheglass_da"
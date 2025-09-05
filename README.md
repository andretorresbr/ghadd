# GoHacking Active Directory Defense (GHADD)
<p align="center">
  <img src="https://firebasestorage.googleapis.com/v0/b/gohacking-prod.appspot.com/o/cursos%2Flogo%2Fz3Orzet4fmUQEc9JnYYj?alt=media&token=41808912-2081-456b-91c5-cd7a29e8771e" alt="Main UI" width="300">
</p>
Repositório de arquivos públicos utilizados no curso GoHacking Active Directory Defense (https://gohacking.com.br/curso/gohacking-active-directory-defense)

## Scripts compartilhados

- [Sync-ADObjectToGroup.ps1](Sync-ADObjectToGroup/README.md): sincroniza todos os computadores ou usuários existentes debaixo da estrutura de uma ou mais OUs e sincroniza com um grupo do AD
- **CriaEstruturaCORP.ps1**: cria todas as OUs, grupos e usuários utilizados nos laboratórios do curso GHADD
- **Remove-JoinACLs.ps1**: comumente existe uma conta que adiciona computadores ao domínio (join accounts). Essas contas possuem DACLs inseguras sobre essas máquinas adicionadas. O script varre as DACLs do domínio e retira as DACLs atribuídas às join accounts e restaura o owner dos objetos.
- **Sync-SiloMembers.ps1**: sincroniza usuários de um grupo a um Authentication Silo

# Instalação do OpenLDAP com esquema brEduPerson no Ubuntu 22.04

## 1. Introdução

Este tutorial apresenta os passos necessários para se fazer a instalação do diretório OpenLDAP com o esquema brEduPerson no Ubuntu Server 22.04 LTS. Será utilizada a abordagem OLC (cn=config) que permite a alteração de configurações em tempo real.

> ATENÇÃO: Este tutorial assume a existência de um servidor [Ubuntu Server 22.04 LTS](https://github.com/frqtech/ubuntu-2204) previamente configurado com o padrão RNP/CAFe.

## 2. Roteiro

2.1. Inicialmente deve ser efetuada a instalação dos pacotes `slapd` e `ldap-utils`. Para tanto copie e cole o seguinte bloco de linhas: 

> ATENÇÃO: Lembre-se de substituir o valor das variáveis `${INSTITUICAO}` (ex.: Universidade Federal do Rio Grande do Sul) e  `${DOMINIO-INSTITUICAO}` (ex.: ufrgs.br).

```
debconf-set-selections <<-EOF
slapd slapd/internal/generated_adminpw password changeit
slapd slapd/internal/adminpw password changeit
slapd slapd/password2 password changeit
slapd slapd/password1 password changeit
slapd slapd/invalid_config boolean true
slapd slapd/move_old_database boolean true
slapd slapd/purge_database boolean false
slapd slapd/no_configuration boolean false
slapd slapd/domain string ${DOMINIO-INSTITUICAO}
slapd shared/organization string ${INSTITUICAO}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/dump_database select when needed
EOF
export DEBIAN_FRONTEND=noninteractive
apt install -y slapd ldap-utils
```

2.2. Para iniciar a configuração do usuário admin do cn=config faça a geração do hash da senhaa. Para tanto, execute o comando a seguir:

```
slappasswd -h {SSHA}
```

2.3. A seguir, crie o arquivo `/root/admin-cn-config.ldif` com o seguinte conteúdo.

> ATENÇÃO: Lembre-se de substituir o valor da variavel `${HASH}` pelo hash gerado anteriormente (2.2).

```
dn: olcDatabase={0}config,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: ${HASH}
```

2.4. Aplique a configuração da senho do usuário admin do cn=config.

```
ldapmodify -H ldapi:// -Y EXTERNAL -f /root/admin-cn-config.ldif
```

2.5. Faça download e importação dos schemas.

```
wget https://raw.githubusercontent.com/frqtech/openldap-2204/main/breduperson.ldif -O /root/breduperson.ldif
wget https://raw.githubusercontent.com/frqtech/openldap-2204/main/eduperson.ldif -O /root/eduperson.ldif
wget https://raw.githubusercontent.com/frqtech/openldap-2204/main/samba.ldif -O /root/samba.ldif
wget https://raw.githubusercontent.com/frqtech/openldap-2204/main/schac.ldif -O /root/schac.ldif
ldapadd -H ldapi:// -Y EXTERNAL -f /root/breduperson.ldif
ldapadd -H ldapi:// -Y EXTERNAL -f /root/eduperson.ldif
ldapadd -H ldapi:// -Y EXTERNAL -f /root/samba.ldif
ldapadd -H ldapi:// -Y EXTERNAL -f /root/schac.ldif
```

2.6. Para liberar o acesso as portas utilizadas para acesso remoto ao LDAP, adicione as linhas a seguir no final do arquivo de regras do firewall `(/etc/default/firewall)`. Em seguida, reinicie o firewall.
```
# Liberação do LDAP                                   #LDAP
iptables -A INPUT -p tcp -m tcp --dport 389 -j ACCEPT #LDAP
iptables -A INPUT -p tcp -m tcp --dport 636 -j ACCEPT #LDAP
                                                      #LDAP
```
```
/etc/init.d/firewall restart
```

2.7. Por fim, para fazer a carga inicial de dados e ajuste de ACLs, execute as linhas abaixo:

```
wget https://raw.githubusercontent.com/frqtech/openldap-2204/main/popula.sh -O /root/popula.sh
chmod +x /root/popula.sh
/root/popula.sh
```
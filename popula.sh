#!/bin/bash

#title                  popula.sh
#description            Carga inicial de dados e ajuste de ACLs
#author                 Rui Ribeiro - rui.ribeiro@cafe.rnp.br
#lastchangeauthor       Rui Ribeiro - rui.ribeiro@cafe.rnp.br
#date                   2023/06/01
#version                1.0.0
#
#changelog              1.0.0 - 2023/06/01 - Initial version for Ubuntu 22.04.

RAIZ_BASE_LDAP="`slapcat | grep "dn: dc" | awk '{print $2}'`"
DC="`slapcat | grep "dc:" | awk '{print $2}'`"
DOMINIO_INST="`hostname -d`"
SENHA_LEITOR_SHIB="1234"
HASH_SENHA_LEITOR_SHIB=$( slappasswd -h {SSHA} -u -s ${SENHA_LEITOR_SHIB} )

cat <<-EOF | slapadd
dn: ou=people,${RAIZ_BASE_LDAP}
objectClass: organizationalUnit
objectClass: top
ou: people

dn: uid=00123456,ou=people,${RAIZ_BASE_LDAP}
objectClass: person
objectClass: inetOrgPerson
objectClass: brPerson
objectClass: schacPersonalCharacteristics
uid: 00123456
brcpf: 12345678900
brpassport: A23456
schacCountryOfCitizenship: Brazil
telephoneNumber: +55 12 34567890
mail: 00123456@${DOMINIO_INST}
cn: Joao
sn: Silva
userPassword: $SENHA_00123456
schacDateOfBirth:19000523

dn: braff=1,uid=00123456,ou=people,${RAIZ_BASE_LDAP}
objectclass: brEduPerson
braff: 1
brafftype: aluno-graduacao
brEntranceDate: 20070205

dn: braff=2,uid=00123456,ou=people,${RAIZ_BASE_LDAP}
objectclass: brEduPerson
braff: 2
brafftype: professor
brEntranceDate: 20070205
brExitDate: 20080330

dn: brvoipphone=1,uid=00123456,ou=people,${RAIZ_BASE_LDAP}
objectclass: brEduVoIP
brvoipphone: 1
brEduVoIPalias: 2345
brEduVoIPtype: pstn
brEduVoIPadmin: uid=00123456,ou=people,${RAIZ_BASE_LDAP}
brEduVoIPcallforward: +55 22 3418 9199
brEduVoIPaddress: 200.157.0.333
brEduVoIPexpiryDate:  20081030
brEduVoIPbalance: 295340
brEduVoIPcredit: 300000

dn: brvoipphone=2,uid=00123456,ou=people,${RAIZ_BASE_LDAP}
objectclass: brEduVoIP
brvoipphone: 2
brvoipalias: 2346
brEduVoIPtype: celular
brEduVoIPadmin: uid=00123456,ou=people,${RAIZ_BASE_LDAP}

dn: brbiosrc=left-middle,uid=00123456,ou=people,${RAIZ_BASE_LDAP}
objectclass: brBiometricData
brbiosrc: left-middle
brBiometricData: ''
brCaptureDate: 20001212

dn: cn=leitor-shib,${RAIZ_BASE_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: leitor-shib
description: Leitor da base para o shibboleth
userPassword: ${HASH_SENHA_LEITOR_SHIB}
EOF

cat > /root/acls.ldif <<-EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: to attrs=userPassword,shadowLastChange by dn.base="cn=leitor-shib,${RAIZ_BASE_LDAP}" read by anonymous auth by self write by * none
olcAccess: to dn.regex="^uid=([^,]+),ou=people,${RAIZ_BASE_LDAP}\$\$" by dn.base="cn=leitor-shib,${RAIZ_BASE_LDAP}" read by * none
olcAccess: to dn.base="" by * read
olcAccess: to * by dn="cn=admin,${RAIZ_BASE_LDAP}" write by * none
EOF

ldapmodify -H ldapi:// -Y EXTERNAL -f /root/acls.ldif
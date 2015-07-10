#!/bin/bash

# Script taken from https://github.com/piwik/plugin-LoginLdap/blob/master/tests/travis/setup_ldap.sh
# install LDAP
echo "Installing LDAP..."
sudo apt-get update > /dev/null
if ! sudo apt-get install slapd ldap-utils -y -qq > /dev/null; then
    echo "Failed to install OpenLDAP!"
fi

# configure LDAP
echo ""
echo "Configuring LDAP..."

mkdir -p $TRAVIS_BUILD_DIR/ldap
sudo chmod -R 777 $TRAVIS_BUILD_DIR/ldap

ADMIN_USER=deathofrats
ADMIN_PASS=squeak
ADMIN_PASS_HASH=`slappasswd -h {md5} -s $ADMIN_PASS`
BASE_DN="dc=ankh-morpork,dc=dw"

STR_OID="1.3.6.1.4.1.1466.115.121.1.15"
VIEW_OID="2.16.840.1.113730.3.1.1.1"
ADMIN_OID="2.16.840.1.113730.3.1.1.2"
SUPERUSER_OID="2.16.840.1.113730.3.1.1.3"

sudo ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: -1
#-
#add: olcDisallows
#olcDisallows: bind_anon
EOF

sudo ldapadd -Y EXTERNAL -H ldapi:/// <<EOF
# database
dn: olcDatabase={2}hdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: {2}hdb
olcRootDN: cn=$ADMIN_USER,$BASE_DN
olcRootPW: $ADMIN_PASS_HASH
olcDbDirectory: $TRAVIS_BUILD_DIR/ldap
olcSuffix: $BASE_DN
olcAccess: {0}to attrs=userPassword,shadowLastChange by self write by dn="cn=$ADMIN_USER,$BASE_DN" write by * auth
olcAccess: {1}to dn.base="" by dn="cn=$ADMIN_USER,$BASE_DN" write by * read
olcAccess: {2}to * by self write by dn="cn=$ADMIN_USER,$BASE_DN" write by * read
#olcRequires: authc
olcLastMod: TRUE
olcDbCheckpoint: 512 30
olcDbConfig: {0}set_cachesize 0 2097152 0
olcDbConfig: {1}set_lk_max_objects 1500
olcDbConfig: {2}set_lk_max_locks 1500
olcDbConfig: {3}set_lk_max_lockers 1500
olcDbIndex: objectClass eq

# modules
dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
objectClass: top
olcModulePath: /usr/lib/ldap
olcModuleLoad: memberof.la
dn: olcOverlay={0}memberof,olcDatabase={2}hdb,cn=config
objectClass: olcConfig
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: top
olcOverlay: memberof

dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectClass: top
olcModuleLoad: refint.la
olcModulePath: /usr/lib/ldap

dn: olcOverlay={1}refint,olcDatabase={2}hdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: {1}refint
olcRefintAttribute: memberof member manager owner
EOF

sudo ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
# first define custom LDAP attributes for access
dn: cn=schema,cn=config
changetype: modify
add: olcAttributeTypes
olcAttributeTypes: ( $VIEW_OID
  NAME 'view'
  DESC 'Describes site IDs user has view access to.'
  EQUALITY caseIgnoreMatch
  ORDERING caseIgnoreOrderingMatch
  SYNTAX $STR_OID )
-
add: olcAttributeTypes
olcAttributeTypes: ( $ADMIN_OID
  NAME 'admin'
  DESC 'Describes site IDs user has admin access to.'
  EQUALITY caseIgnoreMatch
  ORDERING caseIgnoreOrderingMatch
  SYNTAX $STR_OID )
-
add: olcAttributeTypes
olcAttributeTypes: ( $SUPERUSER_OID
  NAME 'superuser'
  DESC 'Marks user as superuser if present.'
  EQUALITY caseIgnoreMatch
  ORDERING caseIgnoreOrderingMatch
  SYNTAX $STR_OID )
EOF

if [ "$?" -ne "0" ]; then
    echo "Failed to add custom attributes!"
    echo ""
    echo "slapd log:"
    sudo grep slapd /var/log/syslog

    exit 1
fi

sudo ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=schema,cn=config
changetype: modify
add: olcObjectClasses
olcObjectClasses: ( 2.16.840.1.113730.3.2.3
   NAME 'zendLdapPerson'
   DESC 'Ldap User'
   SUP inetOrgPerson
   STRUCTURAL
   MAY ( view $ admin $ superuser )
   )
EOF

if [ "$?" -ne "0" ]; then
    echo "Failed to add zendLdapPerson class!"
    echo ""
    echo "slapd log:"
    sudo grep slapd /var/log/syslog

    exit 1
fi

echo "Configured."

# add entries to LDAP
echo ""
echo "Adding entries to LDAP..."

sudo ldapadd -xv -w $ADMIN_PASS -D cn=$ADMIN_USER,$BASE_DN <<EOF
# base dn
dn: $BASE_DN
objectClass: domain
objectClass: top
dc: ankh-morpork

# base dn
dn: dc=uu,$BASE_DN
objectClass: domain
objectClass: top
dc: uu

# seamstresses dn
dn: ou=seamstresses,$BASE_DN
objectClass: organizationalUnit
objectClass: top
ou: seamstresses

# USER ENTRY (pwd: ugh)
dn: cn=Horace Worblehat,dc=uu,$BASE_DN
cn: Horace Worblehat
sn: Worblehat
givenName: Horace
objectClass: zendLdapPerson
objectClass: top
uid: librarian
userPassword: `slappasswd -h {md5} -s ugh`
mobile: 555-555-5555
mail: librarian@unseenuniversity.am

# USER ENTRY (pwd: run!!)
dn: cn=Rincewind,dc=uu,$BASE_DN
cn: Rincewind
objectClass: top
objectClass: zendLdapPerson
sn: Rincewind
givenName: unknown
uid: wizzard
userPassword: `slappasswd -h {md5} -s run!!`
mobile: none
EOF

echo ldapsearch -x -D "cn=$ADMIN_USER,$BASE_DN" -w "$ADMIN_PASS" -b "$BASE_DN"
ldapsearch -x -D "cn=$ADMIN_USER,$BASE_DN" -w "$ADMIN_PASS" -b "$BASE_DN"
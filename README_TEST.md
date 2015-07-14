# README_TEST

LDAP is a strange system.  That said, here are some interesting notes to
help get testing underway.

## On Mac OS.X

Mac OS X comes with openldap installed.  With this, you will need to make
a few changes.  First, the slapd.conf needs to be altered:

    database        bdb
    suffix          "dc=example,dc=com"
    rootdn          "CN=someUser,DC=example,DC=com"
    rootpw          {SSHA}cR8cMV8LTzDpSiInDERB89QnEqpzwzS5

That contains the hashed password for 'insecure'.

Make sure the daemon is running,

Next create the structure that is needed.

Creating top level node, as well as entry for Manager

File: example.com.ldif

        dn: dc=example,dc=com
        dc: example
        description: LDAP Example
        objectClass: dcObject
        objectClass: organization
        o: example

Add this:

        ldapadd -x -D "CN=someUser,DC=example,DC=com" -W -f ./example.com.ldif

    File: manager.example.com.ldif

        dn: CN=someUser,DC=example,DC=com
        cn: someUser
        objectClass: organizationalRole

    Add this:

        ldapadd -x -D "CN=someUser,DC=example,DC=com" -W -f ./manager.example.com.ldif

After this has been added, we can then use something like Apache Studio
for LDAP to handle creating the rest of the required information.

Create the following:
    ou=test,dc=example,dc=com
        objectClass=organizationalUnit
        ou=test

also:
    uid=user1,dc=example,dc=com
        objectClass=posixAccount
        objectClass=simpleSecurityObject
        uid=anotherUser
        userPassword={SSHA}cR8cMV8LTzDpSiInDERB89QnEqpzwzS5


TestConfiguration values:

    export TESTS_ZEND_LDAP_HOST=localhost
    export TESTS_ZEND_LDAP_PORT=389
    export TESTS_ZEND_LDAP_USE_START_TLS=false
    export TESTS_ZEND_LDAP_USE_SSL=false
    export TESTS_ZEND_LDAP_USERNAME="CN=someUser,DC=example,DC=com"
    export TESTS_ZEND_LDAP_PRINCIPAL_NAME="someUser@example.com"
    export TESTS_ZEND_LDAP_PASSWORD="insecure"
    export TESTS_ZEND_LDAP_BIND_REQUIRES_DN=true
    export TESTS_ZEND_LDAP_BASE_DN="OU=Sales,DC=example,DC=com"
    export TESTS_ZEND_LDAP_ACCOUNT_FILTER_FORMAT="(&(objectClass=posixAccount)(uid=%s))"
    export TESTS_ZEND_LDAP_ACCOUNT_DOMAIN_NAME="example.com"
    export TESTS_ZEND_LDAP_ACCOUNT_DOMAIN_NAME_SHORT="EXAMPLE"
    export TESTS_ZEND_LDAP_ALT_USERNAME="anotherUser"
    export TESTS_ZEND_LDAP_ALT_DN="CN=Another User,OU=Sales,DC=example,DC=com"
    export TESTS_ZEND_LDAP_ALT_PASSWORD="insecure"
    export TESTS_ZEND_LDAP_WRITEABLE_SUBTREE="OU=Test,OU=Sales,DC=example,DC=com"
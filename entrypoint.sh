#!/bin/bash
set -ex

if [ -z "$ADMIN_TOKEN" ]; then
    echo >&2 'error: keystone configuration error '
    echo >&2 '  Following variables are missing : ADMIN_TOKEN'
    exit 1
fi

crudini --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN

CONT_IP_ADDRESS=`ifconfig eth0 | grep "inet addr:" | cut -d : -f 2 | cut -d " " -f 1`

declare -A ssl_aaray

ssl_aaray["enable"]="true"
ssl_aaray["certfile"]="/etc/keystone/ssl/certs/keystone.pem"
ssl_aaray["keyfile"]="/etc/keystone/ssl/private/keystonekey.pem"
ssl_aaray["ca_certs"]="/etc/keystone/ssl/certs/ca.pem"
ssl_aaray["ca_key"]="/etc/keystone/ssl/private/cakey.pem"
ssl_aaray["cert_required"]="false"
ssl_aaray["key_size"]="2048"
ssl_aaray["valid_days"]="3650"
ssl_aaray["cert_subject"]="/C=US/ST=Unset/L=Unset/O=Unset/CN=$CONT_IP_ADDRESS"

for key in ${!ssl_aaray[@]}; do
    crudini --set /etc/keystone/keystone.conf ssl ${key} ${ssl_aaray[${key}]}
done

if [ -n "$LDAP_URL" ]; then
    declare -A ldap_array

    ldap_array["url"]=$LDAP_URL
    ldap_array["user"]=$BINDDN_USER
    ldap_array["password"]=$BINDDN_PASSWORD
    ldap_array["user_tree_dn"]=$USER_TREE_DN
    ldap_array["group_tree_dn"]=$GROUP_TREE_DN

    crudini --set /etc/keystone/keystone.conf identity driver ldap
    crudini --set /etc/keystone/keystone.conf identity domain_specific_drivers_enabled true
    crudini --set /etc/keystone/keystone.conf identity domain_config_dir /etc/keystone/domains
    for key in ${!ldap_array[@]}; do
        crudini --set /etc/keystone/keystone.conf ldap ${key} ${ldap_array[${key}]}
    done
fi

mv /etc/keystone/ssl /etc/keystone/ssl.orig
keystone-manage ssl_setup --keystone-user keystone --keystone-group keystone
cp /etc/keystone/ssl/certs/ca.pem /usr/local/keystone/certs
keystone-all --debug --config-file=/etc/keystone/keystone.conf --log-file=/var/log/keystone/keystone.log

#!/bin/bash

#check sudo
if [[ "$(whoami)" != "root" ]]
then
        echo "use sudo"
        exit
fi

#color
GREEN="\e[32m"
ENDCOLOR="\e[0m"
#create path for certs
read -p "Enter path name for certs: " pname
rm -r $pname 2> /dev/null
mkdir $pname

#info for subj
cd $pname
read -p "Enter country: " country
read -p "Enter state: " state
read -p "Enter city: " city
read -p "Enter org: " org
read -p "Enter unit: " unit
read -p "Enter domain: " domain

#info about server
read -p "Enter server IP: " ip
read -p "Enter server name: " servername
site="$servername@$domain"

#openssl config
echo "[ ca ]
default_ca = CA_default
[ CA_default ]
certs = ./
serial = serial
database = index
new_certs_dir = ./
certificate = root.crt
private_key = root.key
default_days = 36500
default_md  = sha256
preserve = no
email_in_dn  = no
nameopt = default_ca
certopt = default_ca
policy = policy_match
[ policy_match ]
commonName = supplied
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
emailAddress = optional
[ req ]
prompt = no
distinguished_name  = default
default_bits = 2048
default_keyfile = priv.pem
default_md = sha256
req_extensions = v3_req
encyrpt_key = no
x509_extensions = v3_ca
[ default ]
commonName = default
[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = critical,CA:true
[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectAltName = @alt_names
[ v3_req ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = $site
IP.1 = $ip">openssl.cnf

#create index and serial
touch index
echo "01" > serial

#create root key
name="root"
openssl genrsa -out $name.key

#create root cert
openssl req -x509 -new -nodes -key $name.key -sha256 -days 1024 -out $name.crt -config openssl.cnf -subj "/C=$country/ST=$state/L=$city/O=$org/OU=$unit/CN=$name/emailAddress=$name@$domain"
echo -e "${GREEN}ROOT CERT CREATED ${ENDCOLOR}"

#create int key
name="int"
openssl genrsa -out $name.key

#create int csr
openssl req -new -sha256 -config openssl.cnf -key $name.key -out $name.csr

#create int cert
openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days 2650 -batch -in $name.csr -out $name.crt -subj "/C=$country/ST=$state/L=$city/O=$org/OU=$unit/CN=$name/emailAddress=$name@$domain"
echo -e "${GREEN}INT CERT CREATED ${ENDCOLOR}"


#create server key
name="$servername"
openssl genrsa -out $name.key

#create server csr
openssl req -new -key $name.key -out $name.csr -config openssl.cnf

#create server cert
openssl x509 -req -in $name.csr -CA int.crt -CAkey int.key -CAcreateserial -sha256 -days 2650 -days 2650 -set_serial 01 -out $name.crt -extensions v3_req -extfile openssl.cnf \
-subj "/C=$country/ST=$state/L=$city/O=$org/OU=$unit/CN=$name/emailAddress=$name@$domain"
echo -e "${GREEN}SERVER CERT CREATED ${ENDCOLOR}"

#create usr key
name="usr"
openssl genrsa -out $name.key

#create usr csr
openssl req -new -key $name.key -out $name.csr -config openssl.cnf

#create usr cert
openssl x509 -req -in $name.csr -CA int.crt -CAkey int.key -CAcreateserial -sha256 -days 2650 -out $name.crt -extensions v3_req -extfile openssl.cnf \
-subj "/C=$country/ST=$state/L=$city/O=$org/OU=$unit/CN=$name/emailAddress=$name@$domain"

echo -e "${GREEN}USR CERT CREATED ${ENDCOLOR}"

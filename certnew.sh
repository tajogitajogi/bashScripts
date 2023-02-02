#!/bin/bash

#check sudo
if [[ "$(whoami)" != "root" ]]
then
	echo "use sudo"
	exit
fi


#create path for certs
read -p "Enter path name for certs: " pname
rm -r $pname 2> /dev/null
mkdir $pname
cd $pname


#cert names
ca="root"
int="intermediate"
read -p "Enter server cert name: " serv
read -p "Enter server IP: " ip
cli="client"

#info for cert
read -p "Enter country: " country
read -p "Enter state: " state
read -p "Enter city: " city
read -p "Enter org: " org
read -p "Enter unit: " unit
read -p "Enter domain: " domain
read -p "Enter password: " pas

#openssl config
echo "[ ca ]
default_ca = CA_default
[ CA_default ]
certs = ./
serial = serial
database = index
new_certs_dir = ./
certificate = $ca.crt
private_key = $ca.key
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
input_password = $pas
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
DNS.0 = $serv@$domain
IP.0 = $ip">openssl.cnf
#create others 
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber


#create root key
name=$ca
openssl genrsa -aes256 -out $name.key 4096  
chmod 400 $name.key


#create root cert
openssl req -new -sha256 -config openssl.cnf -nodes  -key $name.key -x509 -days 3650 -out $name.crt -subj "/C=$country/ST=$state/L=$city/O=$org/OU=$unit/CN=$name/emailAddress=$name@$domain" 
chmod 444 $name.crt


#create int key
name=$int
openssl genrsa -aes256 -out $name.key 4096 
chmod 400 $name.key


#create query for int cert
openssl req -new -sha256 -config openssl.cnf -batch -key $name.key   -out $name.csr 


#verif int cert
openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in $name.csr -out $name.crt -subj "/C=$country/ST=$state/L=$city/O=$org/OU=$unit/CN=$name/emailAddress=$name@$domain"
chmod 444 $name.crt 

#create serv key
name=$serv
openssl genrsa -aes256 -out $name.key 2048
chmod 400 $name.key


#create query for serv cert
openssl req -new -sha256 -config openssl.cnf -key $name.key -out $name.csr


#verif serv cert
openssl x509 -req  -in $name.csr -CA intermediate.crt -CAkey intermediate.key -CAcreateserial -sha256 -days 365 -set_serial 01 -out $name.crt -extensions v3_req -extfile openssl.cnf  -subj "/C=$country/ST=$state/L=$city/O=$org/OU=$unit/CN=$name/emailAddress=$name@$domain"
chmod 444 $name.crt

#create usr key
name=$cli
openssl genrsa -out $name.key


#create query for usr cert
openssl req -new -sha256 -config openssl.cnf -key $name.key -out $name.csr


#verif usr cert
openssl x509 -req -in $name.csr -CA intermediate.crt -CAkey intermediate.key  -CAcreateserial -sha256 -days 365 -out $name.crt -extensions v3_req -exrfile openssl.cnf -subj "/C=$country/ST=$state/L=$city/O=$org/OU=$unit/CN=$name/emailAddress=$name@$domain" 


#export for browser
openssl pkcs12 -export -in $name.crt  -inkey $name.key  -out $name.p12  -password pass:$password
#!/bin/bash

components="anm-int manager-int traffic-int manager-ext portal-ext traffic-ext"

echo "Generate certs for domain $1"
echo "Selected organization : $2"

if [[ -f ../Certs/root-$1.key ]] && [[ -f ../Certs/root-$1.key ]]
then
    echo "root certs for domain $1 already exist."
else
    echo "root certs for domain $1 doesn't exist. Create root cert"
    openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
        -subj "/O=$2 Inc./CN=$1" -keyout ../Certs/root-$1.key \
        -out ../Certs/root-$1.crt
fi

echo "Generate certs for all components"
for i in $components
do
    echo "Generate cert for $i name"
    openssl req -out ../Certs/$i.$1.csr -newkey rsa:2048 \
    -nodes -keyout ../Certs/$i.$1.key -subj '/CN='$1'/O='$2
    echo "Sign cert with CA"
    openssl x509 -req -days 365 -CA ../Certs/root-$1.crt \
        -CAkey ../Certs/root-$1.key -set_serial 0 \
        -in ../Certs/$i.$1.csr -out ../Certs/$i.$1.crt
done
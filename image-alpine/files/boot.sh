#!/bin/bash

set -e

echo '[0] unalias cp'
unalias -a cp

check_apiserver(){
    ck=1
    retry=0
    apiserver="http://${K8S_HOST}:${K8S_PORT}/api"
    while [ $ck -ne 0 -a $retry -lt 10 ]
    do
        curl -s $apiserver
        ck=$?
        let retry=retry+1
        sleep 5
    done
    if [ $retry -lt 10 ] ; then
        return 0
    else
        echo "unable to connect kubernetes apiserver:$apiserver. Refuse to start rabbitmq server."
        return 1	
    fi
}

gen_cookie(){
    cookie='123456789ABCDEFGHIJKLMN'
    if [ $RABBITMQ_ERLANG_COOKIE ]; then
        cookie=$RABBITMQ_ERLANG_COOKIE
    fi

    echo $cookie > /var/lib/rabbitmq/.erlang.cookie
}

echo '[1] test kube-dns ...'
curl -k -s --head https://kubernetes

echo '[2] generate erlang cookie'
gen_cookie 

echo '[3] test connecting to k8s apiserver'
check_apiserver

echo '[4] copy configuration files to /etc/rabbitmq/'
cp -f /tmp/rabbitmq_config/* /etc/rabbitmq/

echo '[5] change directory owner'
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq

echo '[6] rabbitmq starts'
rabbitmq-server -detached

echo '[7] show running logs...'
tail -F /var/log/rabbitmq/${RABBITMQ_NODENAME}.log

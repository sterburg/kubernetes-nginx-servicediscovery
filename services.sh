#!/bin/sh

alias oc=/usr/local/bin/oc
oc login --token="`cat /run/secrets/kubernetes.io/serviceaccount/token`" --certificate-authority="/run/secrets/kubernetes.io/serviceaccount/ca.crt" https://kubernetes.default
oc project `cat /run/secrets/kubernetes.io/serviceaccount/namespace`

oc get services --watch --template='{{ .metadata.name}}
'|while read line
do
  echo $line
  oc get services --template="`cat template`">/etc/nginx/conf.d/dynsvc.conf
  kill -HUP $(ps -ef | grep nginx | grep master | awk '{print $2}')
done


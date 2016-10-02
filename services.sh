#!/bin/sh -x

# == Default values
FILTER=${FILTER:-nginx}


alias oc=/usr/bin/oc

# Login only necessary for Kubernetes. OpenShift auto-login based on /run/secrets serviceaccount
#oc login   --token="`cat /run/secrets/kubernetes.io/serviceaccount/token`"            \
#           --certificate-authority="/run/secrets/kubernetes.io/serviceaccount/ca.crt" \
#           https://kubernetes.default
#oc project `cat /run/secrets/kubernetes.io/serviceaccount/namespace`

# == Status Info
oc whoami
oc project


# == Watch Services
oc get services --watch --template='{{ .metadata.name}}
' |grep --line-buffered "${FILTER}" |while read line
do
  echo "== Found new service: " $line
  oc get services --template="`cat template`" |tee /etc/nginx/conf.d/dynsvc.conf

  # FYI: without '-c' it will take 1st container. Make sure nginx is the 1st container. nginx-dynsvc is 2nd.
  # FYI: PID is always 1 as there is only one process running in a container
  oc rsh "${HOSTNAME}" kill -HUP 1 || echo 'unable to reload nginx'

  # shared PID namespace not available in Kubernetes 1.3 yet...
  #kill -HUP $(ps -ef | grep 'nginx.*master' | awk '{print $2}' || echo 'nginx process not found') || echo 'unable to reload nginx'
done


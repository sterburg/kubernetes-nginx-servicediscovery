# kubernetes-nginx-servicediscovery
sidecar: Create nginx config from go-template based on watching kubernetes services using kubectl

# Setup
```
oc new-project nginx
oc new-app nginx
```

Allow images pulled from docker hub to run as root:
```
oc admin add-scc-to-user anyuid -z default
oc patch dc/nginx --patch='{"spec": {"template": {"spec": {"securityContext": { "runAsUser": 0 }}}}}'
```

Allow container to query services:
```
oc policy add-role-to-user edit -z default
```

Add etc mount shared between both containers
```
oc volume dc/nginx --add --name=cache -m /var/cache/nginx
oc volume dc/nginx --add --name=etc   -m /etc/nginx/conf.d
```

Build sidecar container and add it to the existing nginx deployment:

```
oc new-build --name=nginx-dynsvc .
oc patch dc nginx --patch='
{ "spec": { 
    "template": {
      "spec": {
        "containers": [
          { "name" : "nginx-dynsvc", 
            "image": "172.30.67.71:5000/nginx/nginx-dynsvc:latest",
            "volumeMounts": [
              { "name": "etc", 
                "mountPath": "/etc/nginx/conf.d" } 
            ] 
          }
        ], 
        "triggers": [
          { "type": "ImageChange", 
            "imageChangeParams": { 
              "from": { 
                "kind": "ImageStreamTag",
                "name": "nginx-dynsvc:latest"
              },
              "containerNames": [ 
                "nginx-dynsvc" 
              ] 
            } 
          } 
        ]
      }
    }
  }
}'
```

# Remarks
* Shared PID namespace is not supported by Kubernetes 1.3 yet.
  Either use "hostPID: true" (you need scc 'privileged') in your deploymentconfig
  Or use "oc rsh" (you need role 'edit') to send the kill signal.


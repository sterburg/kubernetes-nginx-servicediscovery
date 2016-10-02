# kubernetes-nginx-servicediscovery
sidecar: Create nginx config from go-template based on watching kubernetes services using kubectl

# Concept
This example explains the following concepts:
* side-car container (one container helping the other. Living in 1 POD)
* service discovery  (listen for changes & adapt yourself)
* ConfigMap (external config)
* Running Docker Hub images on OpenShift (AnyUID policy role)
* Accessing Kube API from withing Container (use ServiceAccount from /run/secrets)
* OpenShift Kubernetes compatibility (Transform OpenShift client "oc" into Kubernetes client "kubectl")


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

Allow container to query services and run rsh:
```
oc policy add-role-to-user edit -z default
```

Add etc mount shared between both containers
```
oc volume dc/nginx --add --name=etc -m /etc/nginx/conf.d
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

If you don't want a static template from your Git repo, but want a dynamic template per environment/namespace/project:
```
oc create configmap templates --from-file=proxy.tpl
oc volume dc/nginx --add -m /templates --source='{"configMap": { "name": "templates"}}'
```


# Usage
* Use ENV FILTER as a "label query" (selector) to only include those services with that label.
* Use ENV TEMPLATE to dynamically choose the template from your list of templates

# Remarks
* Shared PID namespace is not supported by Kubernetes 1.3 yet.
  Either use "hostPID: true" (you need scc 'privileged') in your deploymentconfig
  or use "oc rsh" (you need role 'edit') to send the kill signal.
* "FROM alphine" somehow doesn't mount /run/secrets/serviceaccount.
  Now using "debian:jessie" which is the same base layers as the nginx image used anyway.
* "oc" (openshift client) binary will behave like "kubectl" when it is renamed as "kubectl"


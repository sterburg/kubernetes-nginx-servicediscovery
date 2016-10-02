server {

{{range .items}}
location /{{ .metadata.name}} {
  proxy_pass http://{{ .metadata.name}}:8080;
}
{{end}}

}

bundle: {
  apiVersion: "v1alpha1"
  name:       "demo-app-01"
  instances: {
    "demo-app-01-backend": {
      module: {
        url:     "oci://catalina.azurecr.io/classic-deployment"
        version: "0.2.1"
      }
      namespace: "demo-app-01"
      values: {
        image: {
          repository: "catalina.azurecr.io/cmp/backend"
          tag:        *"latest" | string
          digest:     ""
          pullPolicy: "IfNotPresent"
        }
        replicas: *1 | int
        service: port: 5000
        containerPort: 5000
        probes: {
            liveness: {
                path: "/health"
                initialDelaySeconds: 30
                periodSeconds: 10
            }
            readiness: {
                path: "/health"
                initialDelaySeconds: 5
                periodSeconds: 5
            }
        }
        env: {
          DEBUG: "false"
        }
        resources: {
          requests: {
            cpu:    "100m"
            memory: "128Mi"
          }
          limits: {
            cpu:    "200m"
            memory: "256Mi"
          }
        }
      }
    }
    "demo-app-01-frontend": {
      module: {
        url:     "oci://catalina.azurecr.io/classic-nginx"
        version: "0.3.2"
      }
      namespace: "demo-app-01"
      values: {
        ingress: {
          enabled: true
          annotations: {
            "kubernetes.io/ingress.class": "nginx"
          }
          hosts: [
            {
              host: "demo-app-01.catmktg.com"
              paths: [
                {
                  path:     "/"
                  pathType: "Prefix"
                },
              ]
            },
          ]
        }
        image: {
          repository: "catalina.azurecr.io/cmp/frontend"
          tag:        *"latest" | string
          digest:     ""
          pullPolicy: "IfNotPresent"
        }
        replicas: *1 | int
        message: "Welcome to Demo App 01"
        mountIndexHtml: false
        containerPort: 80
        probes: {
            liveness: { path: "/" }
            readiness: { path: "/" }
        }
        nginxConfig: """
          server {
            listen       80;
            server_name  localhost;
            root /usr/share/nginx/html;
            index index.html;

            location / {
                try_files $uri $uri/ /index.html;
            }

            location /api {
              proxy_pass http://demo-app-01-backend:5000;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
            }
          }
          """
        resources: {
          requests: {
            cpu:    "50m"
            memory: "64Mi"
          }
          limits: {
            cpu:    "100m"
            memory: "128Mi"
          }
        }
      }
    }
  }
}

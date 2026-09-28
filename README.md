# Django Notes App — Docker, Docker Compose & Kubernetes DevOps Project

A containerized Django Notes application deployed with **Docker**, **Docker Compose**, and **Kubernetes**, using **MySQL** as the database and **Nginx** as a reverse proxy.

> This README documents the DevOps work implemented in this repository, including the Docker multi-stage build, three-service Docker Compose stack, Kubernetes manifests, persistent storage, health checks, service discovery, and troubleshooting work.

## Project Overview

This project demonstrates an end-to-end containerization and orchestration workflow:

- Django application containerized with Docker
- Multi-stage Docker build for the Django application
- Gunicorn used as the application server
- MySQL container with persistent storage
- Nginx reverse proxy
- Three-service Docker Compose architecture
- Kubernetes Deployments and Services
- Kubernetes ConfigMap and Secret based configuration
- Kubernetes PersistentVolumeClaim for MySQL
- Readiness and liveness probes
- Kubernetes Service discovery between Django, MySQL, and Nginx
- Troubleshooting of container conflicts, database connectivity, DNS/service naming, storage, health checks, and networking

## Architecture

### Docker Compose

```text
                         Client / Browser
                              |
                              | :80
                              v
                       +-------------+
                       |    Nginx    |
                       | Reverse     |
                       | Proxy       |
                       +------+------+
                              |
                              | :8000
                              v
                       +-------------+
                       |   Django    |
                       |  Gunicorn   |
                       +------+------+
                              |
                              | :3306
                              v
                       +-------------+
                       |    MySQL    |
                       +-------------+
                              |
                              v
                         ./data/mysql
```

### Kubernetes

```text
Client
  |
  v
nginx-service :80
  |
  v
nginx Deployment
  |
  | proxy_pass
  v
notes-app-service :8000
  |
  v
Django Deployment
  |
  | DB_HOST=db-cont :3306
  v
db-cont Service
  |
  v
MySQL Deployment
  |
  v
db-pvc -> /var/lib/mysql
```

## Technology Stack

| Area | Technology |
|---|---|
| Application | Python, Django |
| Application Server | Gunicorn |
| Database | MySQL 8.0 |
| Reverse Proxy | Nginx |
| Containerization | Docker |
| Local Orchestration | Docker Compose |
| Container Orchestration | Kubernetes |
| Storage | Kubernetes PVC |
| Configuration | ConfigMap |
| Secrets | Kubernetes Secret |
| Version Control | Git / GitHub |

## Repository Structure

```text
django-notes-app/
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
├── requirements.txt
├── manage.py
├── README.md
├── nginx/
├── notesapp/
├── mynotes/
├── api/
├── staticfiles/
└── k8s/
    ├── namespace.yml
    ├── db-configmap.yml
    ├── db-secret.example.yml
    ├── db-pvc.yml
    ├── db-deployment.yml
    ├── db-service.yml
    ├── notes-app-deployment.yml
    ├── notes-app-service.yml
    ├── nginx-configmap.yml
    ├── nginx-deployment.yml
    └── nginx-service.yml
```

## Docker — Multi-Stage Build

The application Dockerfile uses two stages:

1. **Builder stage** — installs Python dependencies and MySQL client build dependencies.
2. **Runtime stage** — copies the installed Python packages and application code into a clean Python runtime image.

This keeps compiler/build dependencies out of the final runtime layer.

Build:

```bash
docker build -t django-notes-app .
```

Run:

```bash
docker run -d -p 8000:8000 --name django-notes-app django-notes-app
```

## Docker Compose

The Compose stack contains:

- `nginx` — Nginx reverse proxy on port 80
- `django_app` — Django + Gunicorn on port 8000
- `db` — MySQL 8.0 on port 3306

Start:

```bash
docker compose up -d --build
```

Check:

```bash
docker compose ps
docker ps
```

Logs:

```bash
docker compose logs -f
```

Application:

```text
http://localhost
```

Direct Django access:

```text
http://localhost:8000
```

Stop:

```bash
docker compose down
```

The Compose configuration includes:

- Dedicated Docker network
- MySQL persistent volume
- MySQL health check
- Django health check
- Restart policies
- Service dependencies
- Nginx reverse proxying

## Kubernetes Deployment

The Kubernetes namespace used by this project is:

```text
nginx
```

Apply the resources:

```bash
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/db-configmap.yml
kubectl apply -f k8s/db-secret.example.yml
kubectl apply -f k8s/db-pvc.yml
kubectl apply -f k8s/db-deployment.yml
kubectl apply -f k8s/db-service.yml
kubectl apply -f k8s/notes-app-deployment.yml
kubectl apply -f k8s/notes-app-service.yml
kubectl apply -f k8s/nginx-configmap.yml
kubectl apply -f k8s/nginx-deployment.yml
kubectl apply -f k8s/nginx-service.yml
```

> For a real deployment, create your own `db-secret.yml` from the example with private credentials. Do **not** commit real passwords to GitHub.

Check resources:

```bash
kubectl get all -n nginx
kubectl get pods -n nginx -o wide
kubectl get svc -n nginx
kubectl get pvc -n nginx
```

Access through Nginx:

```bash
kubectl port-forward svc/nginx-service -n nginx 8080:80
```

Open:

```text
http://localhost:8080
```

Direct Django service:

```bash
kubectl port-forward svc/notes-app-service -n nginx 8000:8000
```

## Kubernetes Manifests — Full YAML

### 1. Namespace — `k8s/namespace.yml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nginx
```

### 2. Database ConfigMap — `k8s/db-configmap.yml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-config
  namespace: nginx
data:
  MYSQL_DATABASE: test_db
```

### 3. Database Secret Template — `k8s/db-secret.example.yml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: nginx
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: "change-me"
  DB_USER: "root"
  DB_PASSWORD: "change-me"
```

### 4. Database PVC — `k8s/db-pvc.yml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc
  namespace: nginx
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### 5. Database Deployment — `k8s/db-deployment.yml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-deployment
  namespace: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
        - name: mysql
          image: mysql:8.0
          ports:
            - containerPort: 3306
          env:
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: db-config
                  key: MYSQL_DATABASE
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: MYSQL_ROOT_PASSWORD
          volumeMounts:
            - name: db-data
              mountPath: /var/lib/mysql
          readinessProbe:
            exec:
              command:
                - sh
                - -c
                - mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD"
            initialDelaySeconds: 20
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 6
      volumes:
        - name: db-data
          persistentVolumeClaim:
            claimName: db-pvc
```

### 6. Database Service — `k8s/db-service.yml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-cont
  namespace: nginx
spec:
  selector:
    app: db
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306
  type: ClusterIP
```

### 7. Django Deployment — `k8s/notes-app-deployment.yml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notes-app-deployment
  namespace: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notes-app
  template:
    metadata:
      labels:
        app: notes-app
    spec:
      containers:
        - name: notes-app
          image: khanaffan513/notes-app-k8s:latest
          ports:
            - containerPort: 8000
          env:
            - name: DB_NAME
              value: test_db
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: DB_USER
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: DB_PASSWORD
            - name: DB_HOST
              value: db-cont
            - name: DB_PORT
              value: "3306"
          readinessProbe:
            httpGet:
              path: /admin/
              port: 8000
            initialDelaySeconds: 20
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 6
          livenessProbe:
            httpGet:
              path: /admin/
              port: 8000
            initialDelaySeconds: 45
            periodSeconds: 20
            timeoutSeconds: 5
            failureThreshold: 3
```

### 8. Django Service — `k8s/notes-app-service.yml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: notes-app-service
  namespace: nginx
spec:
  selector:
    app: notes-app
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
  type: ClusterIP
```

### 9. Nginx ConfigMap — `k8s/nginx-configmap.yml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: nginx
data:
  default.conf: |
    server {
      listen 80;
      server_name _;

      location / {
        proxy_pass http://notes-app-service:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      }
    }
```

### 10. Nginx Deployment — `k8s/nginx-deployment.yml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf
      volumes:
        - name: nginx-config
          configMap:
            name: nginx-config
```

### 11. Nginx Service — `k8s/nginx-service.yml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: nginx
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

## Kubernetes Communication

Django → MySQL:

```text
Django Pod
    |
    | db-cont:3306
    v
db-cont Service
    |
    v
MySQL Pod
```

Nginx → Django:

```text
Client
    |
    v
nginx-service:80
    |
    v
Nginx Pod
    |
    | notes-app-service:8000
    v
Django Pod
```

## Troubleshooting Work

Issues handled during the project included:

- Docker container-name conflicts
- Confusion between Docker image IDs and container IDs
- Django/MySQL connectivity
- Kubernetes Service naming and DNS-1035 naming requirements
- Pod and Service connectivity
- Nginx reverse-proxy configuration
- Readiness and liveness probes
- Persistent storage with PVC
- Kubernetes namespace/resource inspection
- Docker Compose service startup and health checks

Example container-name conflict:

```text
The container name "/mysql" is already in use
```

Resolution:

```bash
docker rm -f mysql
```

The key distinction is:

```text
IMAGE ID     -> identifies an image
CONTAINER ID -> identifies a container
CONTAINER NAME -> human-readable container name
```

## DevOps Work Completed

### Docker

- Created a Django Dockerfile.
- Implemented a multi-stage Docker build.
- Installed Python and MySQL dependencies in a builder stage.
- Kept runtime image separate from build dependencies.
- Exposed Django on port 8000.
- Used Gunicorn for containerized application serving.

### Docker Compose

- Built a three-tier stack: Nginx + Django/Gunicorn + MySQL.
- Created isolated Docker networking.
- Added database persistence.
- Added MySQL health checks.
- Added Django health checks.
- Added restart policies.
- Configured Nginx reverse proxying.
- Tested container lifecycle and logs.

### Kubernetes

- Created a dedicated `nginx` namespace.
- Created Django Deployment and ClusterIP Service.
- Created MySQL Deployment and ClusterIP Service.
- Added ConfigMap for database configuration.
- Added Secret-based database credentials.
- Added PersistentVolumeClaim for MySQL data.
- Added Nginx Deployment and Service.
- Added Nginx ConfigMap for reverse proxy configuration.
- Added readiness and liveness probes.
- Used Kubernetes Service discovery for internal communication.
- Tested Pods, Services, logs, port-forwarding, storage, and connectivity.

## Useful Commands

```bash
# Docker
docker ps
docker images
docker compose ps
docker compose logs -f
docker compose down

# Kubernetes
kubectl get pods -n nginx
kubectl get svc -n nginx
kubectl get deployments -n nginx
kubectl get pvc -n nginx
kubectl describe pod <pod-name> -n nginx
kubectl logs <pod-name> -n nginx

# Restart Django
kubectl rollout restart deployment/notes-app-deployment -n nginx

# Access Nginx
kubectl port-forward svc/nginx-service -n nginx 8080:80

# Delete Kubernetes resources
kubectl delete -f k8s/
```

## CV / Resume Project Description

**Django Notes App — Docker & Kubernetes DevOps Deployment**

- Containerized a Django application using Docker and implemented a multi-stage build for a separated build/runtime image workflow.
- Built a Docker Compose stack with Django/Gunicorn, MySQL, and Nginx using isolated networking, health checks, restart policies, and persistent database storage.
- Deployed the application on Kubernetes using Deployments, Services, ConfigMap, Secret, PVC, readiness/liveness probes, and Nginx reverse-proxy configuration.
- Configured Kubernetes Service discovery for Django–MySQL and Nginx–Django communication and troubleshot container conflicts, service naming, storage, health checks, and application connectivity.

## Security Notes

Environment files and local database files should not be committed to the repository. The project now uses `k8s/db-secret.example.yml` as a safe template; create the real Secret locally with your own credentials.

GitHub recommends keeping credentials out of repositories and rotating a credential if it has already been exposed. See the [GitHub secret security guidance](https://docs.github.com/en/get-started/learning-to-code/storing-your-secrets-safely).

## Repository

GitHub: https://github.com/khanaffan513dkxxx-create/django-notes-app

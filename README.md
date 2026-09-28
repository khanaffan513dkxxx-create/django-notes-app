# Django Notes App — Docker & Kubernetes DevOps Project

A containerized Django Notes application deployed with **Docker Compose** and **Kubernetes**, using **MySQL** as the database and **Nginx** as a reverse proxy.

## Project Overview

This project demonstrates a complete containerization and orchestration workflow:

- Django application containerized with Docker
- MySQL database containerized with persistent storage
- Nginx configured as a reverse proxy
- Multi-container local development with Docker Compose
- Kubernetes manifests for namespace, application, database, services, storage, and Nginx
- Health checks and restart policies
- Gunicorn used as the Django application server
- Kubernetes Service-based communication between application components

## Architecture

```text
                    Client / Browser
                          |
                          | :80
                          v
                  +---------------+
                  |     Nginx     |
                  | Reverse Proxy |
                  +-------+-------+
                          |
                          | :8000
                          v
                  +---------------+
                  | Django /      |
                  | Gunicorn App  |
                  +-------+-------+
                          |
                          | MySQL :3306
                          v
                  +---------------+
                  |     MySQL     |
                  |   Database    |
                  +---------------+
                          |
                          v
                    Persistent Data
```

## Technology Stack

| Area | Technology |
|---|---|
| Application | Python, Django |
| App Server | Gunicorn |
| Database | MySQL 8.0 |
| Reverse Proxy | Nginx |
| Containerization | Docker |
| Local Orchestration | Docker Compose |
| Container Orchestration | Kubernetes |
| Storage | Kubernetes PVC |
| Version Control | Git / GitHub |

## Docker Compose

The Compose setup contains three services:

- `nginx` — reverse proxy on port 80
- `django_app` — Django + Gunicorn on port 8000
- `db` — MySQL on port 3306

### Run with Docker Compose

```bash
docker compose up -d --build
```

Check containers:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f
```

Application:

```text
http://localhost
```

Direct Django/Gunicorn access:

```text
http://localhost:8000
```

Stop:

```bash
docker compose down
```

## Dockerfile — Multi-Stage Build

The application Dockerfile uses a builder stage for Python dependencies and a separate runtime stage.

This keeps build tools such as GCC out of the final runtime layer and makes the image structure cleaner.

Build manually:

```bash
docker build -t django-notes-app .
```

Run:

```bash
docker run -d -p 8000:8000 --name django-notes-app django-notes-app
```

## Kubernetes Deployment

The `k8s/` directory contains the complete Kubernetes configuration used for the project.

### Kubernetes resources

```text
k8s/
├── namespace.yml
├── db-configmap.yml
├── db-secret.yml
├── db-pvc.yml
├── db-deployment.yml
├── db-service.yml
├── notes-app-deployment.yml
├── notes-app-service.yml
├── nginx-configmap.yml
├── nginx-deployment.yml
└── nginx-service.yml
```

### Deploy

Create the namespace and application resources:

```bash
kubectl apply -f k8s/
```

Check resources:

```bash
kubectl get all -n nginx
kubectl get pvc -n nginx
```

Check pods:

```bash
kubectl get pods -n nginx -o wide
```

Check services:

```bash
kubectl get svc -n nginx
```

### Access the application

The Nginx Service exposes port 80.

For a local cluster, port-forward the Nginx service:

```bash
kubectl port-forward svc/nginx-service -n nginx 8080:80
```

Then open:

```text
http://localhost:8080
```

> This project uses Nginx directly for application access. An Ingress resource is not required for the current setup.

## Kubernetes Communication

The application communicates with MySQL through the Kubernetes Service:

```text
Django Pod
   |
   | MySQL :3306
   v
db-cont Service
   |
   v
MySQL Pod
```

Nginx communicates with the Django Service:

```text
Client
   |
   v
nginx-service :80
   |
   v
notes-app-service :8000
   |
   v
Django Pod
```

## Useful Kubernetes Commands

```bash
kubectl get pods -n nginx
kubectl get svc -n nginx
kubectl get deployments -n nginx
kubectl get pvc -n nginx
kubectl describe pod <pod-name> -n nginx
kubectl logs <pod-name> -n nginx
```

Restart the Django deployment:

```bash
kubectl rollout restart deployment/notes-app-deployment -n nginx
```

Delete the project resources:

```bash
kubectl delete -f k8s/
```

## DevOps Work Completed

### Containerization
- Created Dockerfile for Django application.
- Added MySQL client build dependency handling.
- Used Gunicorn for containerized Django execution.
- Converted the application Dockerfile to a multi-stage build.
- Built and ran application images locally.

### Docker Compose
- Created a three-tier Compose architecture.
- Connected Django, MySQL, and Nginx through a dedicated Docker network.
- Added MySQL health check.
- Added Django health check.
- Added restart policies.
- Added database volume mapping.
- Configured Nginx reverse proxying.

### Kubernetes
- Created Kubernetes namespace.
- Created Django Deployment and Service.
- Created MySQL Deployment and Service.
- Added Kubernetes Secret and ConfigMap for database configuration.
- Added PersistentVolumeClaim for MySQL data.
- Created Nginx Deployment and Service.
- Configured Nginx to proxy traffic to the Django Service.
- Used Kubernetes Service discovery for internal communication.
- Tested Pods, Services, logs, port-forwarding, and application connectivity.

## Troubleshooting Experience

During deployment, the project involved troubleshooting issues such as:

- Docker container name conflicts
- Container vs. image ID confusion
- Django/MySQL connectivity
- Kubernetes Service naming and DNS requirements
- Pod and Service connectivity
- Nginx reverse-proxy configuration
- Health checks
- Persistent storage
- Kubernetes namespace/resource inspection

## CV / Resume Project Description

**Django Notes App — Docker & Kubernetes Deployment**

- Containerized a Django application with Docker and implemented a multi-stage Docker build for cleaner runtime images.
- Built a Docker Compose stack with Django/Gunicorn, MySQL, and Nginx using isolated service networking, health checks, and persistent database storage.
- Deployed the application on Kubernetes using Deployments, Services, ConfigMap, Secret, PVC, and Nginx reverse proxy configuration.
- Configured Kubernetes Service discovery for Django–MySQL and Nginx–Django communication and troubleshot container, networking, storage, and application connectivity issues.

## Repository

GitHub: https://github.com/khanaffan513dkxxx-create/django-notes-app

#!/bin/bash
# K8s-Ops-Box Demo Application - Quick Commands

# Navigate to project directory
cd /home/mkononen/pet-projects/helm/projects-examples/demo-app-01/

# ==========================================
# DOCKER COMPOSE COMMANDS
# ==========================================

# Start the application (build and run in background)
docker compose up --build -d

# Start without rebuilding
docker compose up -d

# Stop the application
docker compose down

# Stop and remove volumes
docker compose down -v

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f backend
docker compose logs -f frontend

# Check container status
docker compose ps

# Restart services
docker compose restart

# Rebuild specific service
docker compose build backend
docker compose build frontend

# ==========================================
# ACCESS URLs
# ==========================================

# Frontend Landing Page
# http://localhost:8080

# Backend API Base URL
# http://localhost:5001

# Health Checks
# curl http://localhost:5001/health
# curl http://localhost:8080/health

# API Endpoints
# curl http://localhost:5001/api/info
# curl http://localhost:5001/api/features
# curl http://localhost:5001/api/architecture
# curl http://localhost:5001/api/screenshots
# curl http://localhost:5001/api/documentation
# curl http://localhost:5001/api/contacts

# Metrics
# curl http://localhost:5001/metrics

# ==========================================
# DOCKER COMMANDS
# ==========================================

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs k8s-ops-box-backend
docker logs k8s-ops-box-frontend

# Follow container logs
docker logs -f k8s-ops-box-backend
docker logs -f k8s-ops-box-frontend

# Execute command in container
docker exec -it k8s-ops-box-backend bash
docker exec -it k8s-ops-box-frontend sh

# Inspect container
docker inspect k8s-ops-box-backend
docker inspect k8s-ops-box-frontend

# Check container health
docker inspect --format='{{.State.Health.Status}}' k8s-ops-box-backend
docker inspect --format='{{.State.Health.Status}}' k8s-ops-box-frontend

# View container resource usage
docker stats

# ==========================================
# DEVELOPMENT COMMANDS
# ==========================================

# Backend Development (without Docker)
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py

# Frontend Development (without Docker)
cd frontend
python -m http.server 8080
# Or use any static file server

# ==========================================
# TESTING COMMANDS
# ==========================================

# Test backend health
curl -s http://localhost:5001/health | jq

# Test all API endpoints
curl -s http://localhost:5001/api/info | jq
curl -s http://localhost:5001/api/features | jq
curl -s http://localhost:5001/api/architecture | jq
curl -s http://localhost:5001/api/screenshots | jq
curl -s http://localhost:5001/api/documentation | jq
curl -s http://localhost:5001/api/contacts | jq

# Test frontend
curl -I http://localhost:8080

# Load test (requires hey or ab)
# hey -n 100 -c 10 http://localhost:5001/api/info

# ==========================================
# CLEANUP COMMANDS
# ==========================================

# Remove all demo app containers
docker rm -f k8s-ops-box-backend k8s-ops-box-frontend

# Remove demo app images
docker rmi demo-app-01-backend demo-app-01-frontend

# Remove demo app network
docker network rm demo-app-01_k8s-ops-box-network

# Full cleanup (containers + images + volumes)
docker compose down -v --rmi all

# ==========================================
# TROUBLESHOOTING
# ==========================================

# Check if ports are in use
sudo netstat -tulpn | grep :8080
sudo netstat -tulpn | grep :5001

# Check container health status
docker compose ps

# View detailed error logs
docker compose logs --tail=100 backend
docker compose logs --tail=100 frontend

# Restart unhealthy containers
docker compose restart backend
docker compose restart frontend

# Rebuild from scratch
docker compose down -v
docker compose build --no-cache
docker compose up -d

# ==========================================
# KUBERNETES DEPLOYMENT (Future)
# ==========================================

# Apply manifests (when created)
# kubectl apply -f k8s/

# Port forward services
# kubectl port-forward svc/k8s-ops-box-frontend 8080:80
# kubectl port-forward svc/k8s-ops-box-backend 5001:5000

# Check pod status
# kubectl get pods -l app=k8s-ops-box-demo

# View logs
# kubectl logs -l app=k8s-ops-box-demo -c backend
# kubectl logs -l app=k8s-ops-box-demo -c frontend

# ==========================================
# USEFUL ALIASES (add to ~/.bashrc)
# ==========================================

# alias demo-start='cd /home/mkononen/pet-projects/helm/projects-examples/demo-app-01 && docker compose up -d'
# alias demo-stop='cd /home/mkononen/pet-projects/helm/projects-examples/demo-app-01 && docker compose down'
# alias demo-logs='cd /home/mkononen/pet-projects/helm/projects-examples/demo-app-01 && docker compose logs -f'
# alias demo-restart='cd /home/mkononen/pet-projects/helm/projects-examples/demo-app-01 && docker compose restart'
# alias demo-rebuild='cd /home/mkononen/pet-projects/helm/projects-examples/demo-app-01 && docker compose down && docker compose up --build -d'

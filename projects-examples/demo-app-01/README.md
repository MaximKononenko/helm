# K8s-Ops-Box Demo Application

A professional demo application showcasing the **K8s-Ops-Box** platform - a comprehensive Kubernetes operations management solution. This application features a modern landing page with detailed information about features, architecture, screenshots, and documentation.

## 🎯 Purpose

This demo application is designed to:
- Introduce K8s-Ops-Box to stakeholders and companies
- Showcase platform capabilities and architecture
- Provide a professional, presentable interface
- Demonstrate the platform's value proposition

## 🏗️ Architecture

The application consists of two microservices:

### Backend (Flask API)
- **Technology**: Python 3.11 + Flask 3.0
- **Port**: 5000 (internal), 5001 (external)
- **Features**:
  - RESTful API endpoints
  - Health check and readiness probes
  - Prometheus metrics endpoint
  - CORS support for frontend integration

### Frontend (Static Web App)
- **Technology**: HTML5, CSS3, JavaScript (Vanilla)
- **Server**: Nginx Alpine
- **Port**: 80 (internal), 8080 (external)
- **Features**:
  - Modern, responsive design with dark theme
  - Interactive welcome carousel
  - Dynamic content loading from backend
  - Glowing UI effects and smooth animations
  - Mobile-friendly interface

## 🎨 Design Elements

### Dark Theme
The application uses a sleek dark theme inspired by the k8s-ops-box UI, featuring:
- Dark backgrounds with contrasting text
- Glowing effects on interactive elements
- Gradient accents for visual appeal
- Improved readability and reduced eye strain

### Welcome Carousel
- Two-slide carousel that explains the value proposition
- Slide 1: Presents common business challenges
- Slide 2: Introduces ops-box as the solution
- Alternative text suggestions available in CAROUSEL_SUGGESTIONS.md

### Brand Assets
- Logo: Using OB-logo-black-bg.png from k8s-ops-box
- Favicon: Using favicon.png from k8s-ops-box
- Slide images: Using slide1.png and slide2.png from k8s-ops-box docs

## 📁 Project Structure

```
demo-app-01/
├── backend/
│   ├── app.py              # Flask application with API endpoints
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile          # Backend container image
├── frontend/
│   ├── index.html          # Main landing page
│   ├── css/
│   │   └── style.css       # Modern, professional dark styling
│   ├── js/
│   │   └── app.js          # Dynamic content loading and carousel
│   ├── img/                # Images directory
│   │   ├── OB-logo-black-bg.png  # Logo from k8s-ops-box
│   │   ├── favicon.png     # Favicon from k8s-ops-box
│   │   ├── slide1.png      # Carousel slide 1
│   │   └── slide2.png      # Carousel slide 2
│   ├── nginx.conf          # Nginx configuration
│   └── Dockerfile          # Frontend container image
├── docker-compose.yml      # Local development setup
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Git (for cloning)

### Local Development

1. **Clone the repository** (if not already done):
   ```bash
   cd helm/projects-examples/demo-app-01/
   ```

2. **Start the application**:
   ```bash
   docker-compose up --build
   ```

3. **Access the application**:
   - Frontend: http://localhost:8080
   - Backend API: http://localhost:5001
   - Health Check: http://localhost:5001/health
   - Metrics: http://localhost:5001/metrics

4. **Stop the application**:
   ```bash
   docker-compose down
   ```

### Production Build

Build individual containers:

```bash
# Build backend
cd backend
docker build -t k8s-ops-box-backend:latest .

# Build frontend
cd ../frontend
docker build -t k8s-ops-box-frontend:latest .
```

## 🔌 API Endpoints

The backend provides the following endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check endpoint |
| `/ready` | GET | Readiness probe |
| `/metrics` | GET | Prometheus metrics |
| `/api/info` | GET | Project information |
| `/api/features` | GET | Platform features list |
| `/api/architecture` | GET | Architecture components and data flow |
| `/api/screenshots` | GET | Screenshot metadata |
| `/api/documentation` | GET | Documentation links |
| `/api/contacts` | GET | Team contact information |

### Example API Response

```bash
# Get project info
curl http://localhost:5001/api/info

# Get features
curl http://localhost:5001/api/features

# Get architecture details
curl http://localhost:5001/api/architecture
```

## 🎨 Features

### Landing Page Sections

1. **Hero Section**
   - Eye-catching headline with gradient text
   - Call-to-action buttons
   - Key metrics display

2. **Features Grid**
   - RBAC Management
   - GitOps Integration
   - ADO Pipeline Manager
   - Event-Driven Architecture

3. **Architecture Overview**
   - Component details
   - Technology stack
   - Data flow visualization

4. **Screenshots Slider**
   - Interactive carousel
   - Auto-play functionality
   - Manual navigation controls

5. **Documentation**
   - Getting Started guides
   - API documentation
   - Deployment instructions

6. **Contact Section**
   - Team information
   - GitHub links
   - Email contacts

## 🎨 Design System

### Color Palette
- Primary: `#0066FF` (Blue)
- Secondary: `#00D4FF` (Cyan)
- Dark Background: `#0A0E27`
- Light Background: `#1A1E3E`

### Typography
- Font Family: Inter (Google Fonts)
- Headings: 700 weight
- Body: 400-500 weight

### Components
- Border Radius: 12px
- Shadows: Multi-level (sm, md, lg)
- Transitions: 0.3s ease

## 🔧 Configuration

### Environment Variables

Backend (`backend/app.py`):
- `FLASK_ENV`: Set to `production` for production builds
- `PORT`: Flask server port (default: 5000)

Frontend (`frontend/js/app.js`):
- `API_BASE_URL`: Backend API URL (auto-detected)

### Nginx Configuration

The frontend nginx server:
- Serves static files with caching
- Proxies API requests to backend
- Enables gzip compression
- Adds security headers

## 📊 Monitoring

### Health Checks

Both services include health check endpoints:

```bash
# Backend health
curl http://localhost:5001/health

# Frontend health
curl http://localhost:8080/health
```

### Metrics

Prometheus metrics available at:
```bash
curl http://localhost:5001/metrics
```

## 🐳 Docker Details

### Backend Image
- Base: `python:3.11-slim`
- Size: ~150MB
- User: Non-root (appuser)
- Workers: 2 Gunicorn workers

### Frontend Image
- Base: `nginx:alpine`
- Size: ~25MB
- Includes: Static files + nginx config

## 🚢 Kubernetes Deployment

### Using Helm (Coming Soon)

```bash
# Install the chart
helm install k8s-ops-box-demo ./helm/k8s-ops-box-demo

# Upgrade
helm upgrade k8s-ops-box-demo ./helm/k8s-ops-box-demo

# Uninstall
helm uninstall k8s-ops-box-demo
```

### Using kubectl

```bash
# Apply manifests
kubectl apply -f k8s/

# Check status
kubectl get pods -l app=k8s-ops-box-demo

# Port forward
kubectl port-forward svc/k8s-ops-box-frontend 8080:80
```

## 🔐 Security

- No hardcoded secrets
- Non-root container users
- Security headers enabled
- CORS properly configured
- Health checks implemented

## 📝 Development

### Local Development Without Docker

#### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

#### Frontend
```bash
cd frontend
# Serve with any static file server
python -m http.server 8080
# Or use live-server, serve, etc.
```

### Adding New Features

1. **Backend**: Add new endpoints in `backend/app.py`
2. **Frontend**: Update `frontend/js/app.js` to fetch and display data
3. **Styling**: Modify `frontend/css/style.css`

## 🤝 Contributing

This is a demo application for K8s-Ops-Box. For contributions to the main platform, please refer to the main repository.

## 📄 License

[Your License Here]

## 📞 Contact

- **Project Lead**: [Name]
- **Email**: [Email]
- **GitHub**: [Repository URL]

## 🗺️ Roadmap

- [x] Backend API implementation
- [x] Frontend landing page
- [x] Docker containerization
- [x] Docker Compose setup
- [ ] Helm chart creation
- [ ] Real screenshots integration
- [ ] CI/CD pipeline
- [ ] Kubernetes manifests
- [ ] Performance optimization

## 📚 Additional Resources

- [K8s-Ops-Box Documentation](../../../k8s-ops-box/docs/)
- [Architecture Guide](../../../k8s-ops-box/docs/architecture.md)
- [ADO Manager Roadmap](../../../k8s-ops-box/docs/ado-manager-roadmap.md)

---

**Built with ❤️ for Kubernetes Operations**

# K8s-Ops-Box Demo Backend API
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
import os
import logging

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Project information
PROJECT_INFO = {
    "name": "K8s-Ops-Box",
    "tagline": "Kubernetes Operations Management Platform",
    "version": "1.0.0",
    "description": "A comprehensive platform for managing Kubernetes RBAC, GitOps workflows, and ADO Pipeline automation"
}

FEATURES = [
    {
        "id": "rbac",
        "title": "RBAC Management",
        "icon": "shield",
        "description": "Simplified Kubernetes RBAC with role templates and group management",
        "benefits": [
            "Pre-configured role templates (Admin, Developer, Viewer)",
            "Team-based access control",
            "GitOps-driven RBAC definitions",
            "Audit trail for all permission changes"
        ]
    },
    {
        "id": "gitops",
        "title": "GitOps Integration",
        "icon": "git",
        "description": "Multi-purpose Git repository management with automated sync",
        "benefits": [
            "Multiple Git purposes (CR, Templates, Output, Source)",
            "Automated synchronization with configurable intervals",
            "Support for HTTPS and SSH authentication",
            "Real-time CR updates from Git commits"
        ]
    },
    {
        "id": "ado",
        "title": "ADO Pipeline Manager",
        "icon": "pipeline",
        "description": "Visual pipeline designer with template-based generation",
        "benefits": [
            "Wizard-based pipeline creation",
            "Advanced YAML editor with tree navigation",
            "Deploy profiles management",
            "Preview before export to Git"
        ]
    },
    {
        "id": "events",
        "title": "Event Streaming",
        "icon": "activity",
        "description": "Real-time event tracking with Redis Streams",
        "benefits": [
            "Severity-based filtering (INFO, WARNING, ERROR, CRITICAL)",
            "Event history with timestamps",
            "WebSocket real-time updates",
            "Event caching for performance"
        ]
    }
]

ARCHITECTURE = {
    "components": [
        {
            "name": "BFF-API",
            "description": "Backend for Frontend - Main API gateway",
            "tech": "FastAPI, Python",
            "responsibilities": [
                "API gateway for all UI requests",
                "Cache management (Redis)",
                "Session management",
                "Authentication & Authorization"
            ]
        },
        {
            "name": "CC-Operator",
            "description": "Control Center Operator - Core Kubernetes controller",
            "tech": "Kopf, Python",
            "responsibilities": [
                "Watch Custom Resources (CRs)",
                "Git operations (clone, sync, commit)",
                "Event publishing to Redis Streams",
                "CR reconciliation loops"
            ]
        },
        {
            "name": "Message Processor",
            "description": "Event consumer and cache updater",
            "tech": "Python, Redis Streams",
            "responsibilities": [
                "Consume events from Redis Streams",
                "Update cache with CR changes",
                "Event severity classification",
                "Cache warming and maintenance"
            ]
        },
        {
            "name": "UI",
            "description": "React-based user interface",
            "tech": "React, TypeScript, Ant Design",
            "responsibilities": [
                "RBAC management UI",
                "GitDefinition configuration",
                "ADO Pipeline wizard and editor",
                "Real-time event dashboard"
            ]
        }
    ],
    "dataFlow": [
        "User interacts with UI",
        "UI calls BFF-API endpoints",
        "BFF-API reads from cache or queries K8s",
        "CC-Operator watches K8s CRs",
        "CC-Operator publishes events to Redis",
        "Message Processor consumes events",
        "Message Processor updates cache",
        "UI receives real-time updates via WebSocket"
    ]
}

SCREENSHOTS = [
    {
        "id": "rbac-list",
        "title": "RBAC Definitions List",
        "description": "Manage RBAC definitions with filtering and search",
        "path": "/screenshots/rbac-list.png"
    },
    {
        "id": "ado-wizard",
        "title": "ADO Pipeline Wizard",
        "description": "Step-by-step pipeline creation with language templates",
        "path": "/screenshots/ado-wizard.png"
    },
    {
        "id": "ado-editor",
        "title": "Advanced Pipeline Editor",
        "description": "Tree-based navigation with YAML editing",
        "path": "/screenshots/ado-editor.png"
    },
    {
        "id": "git-sources",
        "title": "Git Sources Management",
        "description": "Configure Git repositories with multiple purposes",
        "path": "/screenshots/git-sources.png"
    },
    {
        "id": "events-dashboard",
        "title": "Real-time Events Dashboard",
        "description": "Monitor system events with severity filtering",
        "path": "/screenshots/events-dashboard.png"
    }
]

DOCUMENTATION = [
    {
        "category": "Getting Started",
        "links": [
            {"title": "Quick Start Guide", "url": "/docs/quick-start"},
            {"title": "Installation", "url": "/docs/installation"},
            {"title": "Architecture Overview", "url": "/docs/architecture"}
        ]
    },
    {
        "category": "Features",
        "links": [
            {"title": "RBAC Management", "url": "/docs/rbac"},
            {"title": "GitOps Integration", "url": "/docs/gitops"},
            {"title": "ADO Pipeline Manager", "url": "/docs/ado-manager"}
        ]
    },
    {
        "category": "Operations",
        "links": [
            {"title": "Deployment Guide", "url": "/docs/deployment"},
            {"title": "Configuration", "url": "/docs/configuration"},
            {"title": "Monitoring & Troubleshooting", "url": "/docs/monitoring"}
        ]
    }
]

CONTACTS = {
    "team": [
        {
            "name": "Platform Team",
            "role": "Maintainers",
            "email": "platform-team@company.com",
            "slack": "#ops-box-support"
        }
    ],
    "github": "https://github.com/MaximKononenko/k8s-rbac-manager",
    "documentation": "https://docs.ops-box.io"
}

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Kubernetes probes"""
    return jsonify({
        "status": "healthy",
        "service": "ops-box-demo-backend",
        "version": PROJECT_INFO["version"]
    }), 200

# Ready check endpoint
@app.route('/ready', methods=['GET'])
def ready_check():
    """Readiness check endpoint"""
    return jsonify({
        "status": "ready",
        "service": "ops-box-demo-backend"
    }), 200

# Metrics endpoint
@app.route('/metrics', methods=['GET'])
def metrics():
    """Simple metrics endpoint"""
    return jsonify({
        "requests_total": 0,
        "uptime_seconds": 0
    }), 200

# API endpoints
@app.route('/api/info', methods=['GET'])
def get_info():
    """Get project information"""
    logger.info("GET /api/info")
    return jsonify(PROJECT_INFO), 200

@app.route('/api/features', methods=['GET'])
def get_features():
    """Get features list"""
    logger.info("GET /api/features")
    return jsonify(FEATURES), 200

@app.route('/api/architecture', methods=['GET'])
def get_architecture():
    """Get architecture information"""
    logger.info("GET /api/architecture")
    return jsonify(ARCHITECTURE), 200

@app.route('/api/screenshots', methods=['GET'])
def get_screenshots():
    """Get screenshots list"""
    logger.info("GET /api/screenshots")
    return jsonify(SCREENSHOTS), 200

@app.route('/api/documentation', methods=['GET'])
def get_documentation():
    """Get documentation links"""
    logger.info("GET /api/documentation")
    return jsonify(DOCUMENTATION), 200

@app.route('/api/contacts', methods=['GET'])
def get_contacts():
    """Get contact information"""
    logger.info("GET /api/contacts")
    return jsonify(CONTACTS), 200

# Root endpoint
@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        "service": "K8s-Ops-Box Demo Backend",
        "version": PROJECT_INFO["version"],
        "endpoints": {
            "health": "/health",
            "ready": "/ready",
            "metrics": "/metrics",
            "info": "/api/info",
            "features": "/api/features",
            "architecture": "/api/architecture",
            "screenshots": "/api/screenshots",
            "documentation": "/api/documentation",
            "contacts": "/api/contacts"
        }
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('DEBUG', 'false').lower() == 'true'
    
    logger.info(f"Starting K8s-Ops-Box Demo Backend on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)

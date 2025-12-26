/**
 * Health Check Routes
 * {{PROJECT_NAME}}
 * 
 * Provides health check endpoints for Kubernetes probes.
 */

const express = require('express');

const router = express.Router();

// Track startup time
const startupTime = new Date();

/**
 * Liveness probe
 * Returns 200 if the service is running
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

/**
 * Readiness probe
 * Returns 200 if the service is ready to accept traffic
 */
router.get('/ready', (req, res) => {
  // Add checks for dependencies (database, cache, etc.)
  const isReady = true;
  
  if (isReady) {
    res.json({
      status: 'ready',
      timestamp: new Date().toISOString()
    });
  } else {
    res.status(503).json({
      status: 'not ready',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * Detailed health check
 * Returns comprehensive health information
 */
router.get('/health/details', (req, res) => {
  const uptime = Math.floor((Date.now() - startupTime.getTime()) / 1000);
  
  res.json({
    status: 'healthy',
    service: '{{PROJECT_NAME}}',
    version: '1.0.0',
    uptime: `${uptime}s`,
    startedAt: startupTime.toISOString(),
    timestamp: new Date().toISOString(),
    memory: {
      used: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
      total: `${Math.round(process.memoryUsage().heapTotal / 1024 / 1024)}MB`
    },
    dependencies: {
      // Add dependency health checks here
    }
  });
});

module.exports = router;

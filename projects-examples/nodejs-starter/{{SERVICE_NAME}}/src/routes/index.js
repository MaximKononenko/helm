/**
 * Route Aggregator
 * {{OB_PROJECT_NAME}}
 * 
 * Combines all route modules.
 */

const express = require('express');
const healthRoutes = require('./health');

const router = express.Router();

// Health check routes
router.use('/', healthRoutes);

// API v1 routes
router.get('/api/v1/hello', (req, res) => {
  res.json({
    message: 'Hello from {{OB_PROJECT_NAME}}!',
    timestamp: new Date().toISOString(),
    requestId: req.id
  });
});

// Root endpoint
router.get('/', (req, res) => {
  res.json({
    service: '{{OB_PROJECT_NAME}}',
    version: '1.0.0',
    status: 'running',
    documentation: '/api/v1'
  });
});

module.exports = router;

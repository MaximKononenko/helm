/**
 * Application Configuration
 * {{OB_PROJECT_NAME}}
 * 
 * Loads configuration from environment variables.
 */

require('dotenv').config();

const config = {
  // Service identity
  serviceName: process.env.SERVICE_NAME || '{{OB_PROJECT_NAME}}',
  
  // Environment
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Server
  port: parseInt(process.env.PORT, 10) || {{PORT}},
  
  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',
  
  // Feature flags
  features: {
    metricsEnabled: process.env.METRICS_ENABLED === 'true',
    tracingEnabled: process.env.TRACING_ENABLED === 'true'
  }
};

// Validate required configuration
const requiredEnvVars = [];

for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Missing required environment variable: ${envVar}`);
  }
}

module.exports = config;

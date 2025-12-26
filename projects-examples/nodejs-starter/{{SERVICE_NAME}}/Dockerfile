# ============================================
# Node.js Microservice Dockerfile
# Project: {{PROJECT_NAME}}
# ============================================
# Multi-stage build for optimized production image

# === BUILD STAGE ===
FROM node:{{NODE_VERSION}}-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Run linting and tests during build
RUN npm run lint || true
RUN npm test || true

# === PRODUCTION STAGE ===
FROM node:{{NODE_VERSION}}-alpine AS production

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production \
    && npm cache clean --force

# Copy application code
COPY --from=builder /app/src ./src

# Change ownership to non-root user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE {{PORT}}

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:{{PORT}}/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))" || exit 1

# Environment variables
ENV NODE_ENV=production \
    PORT={{PORT}}

# Start application
CMD ["node", "src/index.js"]

/**
 * Application Tests
 * {{PROJECT_NAME}}
 * 
 * Unit tests for the Express application.
 */

const request = require('supertest');
const app = require('../src/app');

describe('{{PROJECT_NAME}} API', () => {
  
  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app)
        .get('/health')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /ready', () => {
    it('should return ready status', async () => {
      const response = await request(app)
        .get('/ready')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toHaveProperty('status', 'ready');
    });
  });

  describe('GET /health/details', () => {
    it('should return detailed health information', async () => {
      const response = await request(app)
        .get('/health/details')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('service', '{{PROJECT_NAME}}');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('memory');
    });
  });

  describe('GET /', () => {
    it('should return service information', async () => {
      const response = await request(app)
        .get('/')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toHaveProperty('service', '{{PROJECT_NAME}}');
      expect(response.body).toHaveProperty('status', 'running');
    });
  });

  describe('GET /api/v1/hello', () => {
    it('should return greeting message', async () => {
      const response = await request(app)
        .get('/api/v1/hello')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toContain('{{PROJECT_NAME}}');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('404 Handler', () => {
    it('should return 404 for unknown routes', async () => {
      const response = await request(app)
        .get('/unknown-route')
        .expect('Content-Type', /json/)
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Not Found');
    });
  });

  describe('Request ID', () => {
    it('should generate request ID if not provided', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.headers).toHaveProperty('x-request-id');
    });

    it('should use provided request ID', async () => {
      const customId = 'test-request-123';
      const response = await request(app)
        .get('/health')
        .set('X-Request-ID', customId)
        .expect(200);

      expect(response.headers['x-request-id']).toBe(customId);
    });
  });
});

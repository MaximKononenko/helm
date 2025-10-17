const request = require('supertest');
const app = require('./server');

describe('Demo API Tests', () => {
  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
    });
  });

  describe('GET /api/hello', () => {
    it('should return hello message', async () => {
      const response = await request(app).get('/api/hello');
      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Hello from Demo API!');
    });
  });

  describe('GET /api/users', () => {
    it('should return list of users', async () => {
      const response = await request(app).get('/api/users');
      expect(response.status).toBe(200);
      expect(response.body.users).toHaveLength(3);
    });
  });

  describe('POST /api/users', () => {
    it('should create a new user', async () => {
      const newUser = { name: 'Dave', role: 'user' };
      const response = await request(app)
        .post('/api/users')
        .send(newUser);
      expect(response.status).toBe(201);
      expect(response.body.name).toBe('Dave');
    });
  });
});

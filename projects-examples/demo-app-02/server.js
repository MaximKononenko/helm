const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API endpoints
app.get('/api/hello', (req, res) => {
  res.json({ 
    message: 'Hello from Demo API!',
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/api/users', (req, res) => {
  res.json({
    users: [
      { id: 1, name: 'Alice', role: 'admin' },
      { id: 2, name: 'Bob', role: 'user' },
      { id: 3, name: 'Charlie', role: 'user' }
    ]
  });
});

app.post('/api/users', (req, res) => {
  const { name, role } = req.body;
  res.status(201).json({
    id: 4,
    name,
    role,
    created: new Date().toISOString()
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Demo API server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

module.exports = app;

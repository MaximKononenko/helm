# Demo API

Simple Node.js Express API for testing ADO Pipeline Manager.

## Features

- Health check endpoint
- REST API endpoints
- Docker support
- Unit tests

## Endpoints

- `GET /health` - Health check
- `GET /api/hello` - Hello message
- `GET /api/users` - List users
- `POST /api/users` - Create user

## Local Development

```bash
npm install
npm start
```

## Testing

```bash
npm test
```

## Docker

```bash
docker build -t demo-api:latest .
docker run -p 3000:3000 demo-api:latest
```

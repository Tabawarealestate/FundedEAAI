# DEPLOYMENT GUIDE — HIKIMA X10 AI

## 1. Docker Deployment
The platform includes Docker and Docker Compose definitions for containerized production deployment.

To launch all services (API Server, PostgreSQL, Redis):
```bash
docker-compose up -d --build
```

## 2. Environment Setup
Set `NODE_ENV=production` and ensure production secret keys and provider credentials are configured in `.env`.

## 3. Database Migration
```bash
docker-compose exec app npx prisma db push
```

## 4. Health Checks
Check server status:
```bash
curl http://localhost:3000/api/v1/health
```

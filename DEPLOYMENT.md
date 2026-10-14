# PRODUCTION DEPLOYMENT SPECIFICATION — HIKIMA X10 AI

This guide details the independent production deployment requirements for **Hikima X10 AI**.

---

## 1. Environment Variables (.env)

Production requires the following environment variables (defined in `.env.example`):

```env
TELEGRAM_BOT_TOKEN=
TELEGRAM_ADMIN_CHAT_ID=
TWELVE_DATA_API_KEY=
CRYPTOMUS_MERCHANT_ID=
CRYPTOMUS_API_KEY=
DATABASE_URL=
REDIS_URL=
JWT_SECRET=
DEFAULT_FREE_ACCESS_CODE=
```

---

## 2. Infrastructure Requirements

- **Database:** PostgreSQL 16+ (`DATABASE_URL`).
- **Cache / Queue:** Redis 7+ (`REDIS_URL`).
- **Telegram Single Polling Instance:** Exactly ONE production process must run Telegram long polling at any time. Running multiple polling processes with the same `TELEGRAM_BOT_TOKEN` will cause Telegram `HTTP 409 Conflict` errors.

---

## 3. Production Build & Start Commands

```bash
# 1. Install production dependencies
npm install

# 2. Generate Prisma Client
npx prisma generate

# 3. Apply database migrations
npx prisma migrate deploy

# 4. Compile TypeScript
npm run build

# 5. Start long-running production service
npm start
```

`npm start` launches:
- HTTP Express REST API on `PORT` (default 3000)
- Single-instance Telegram Bot long-polling service (`@HikimaAIbot`)
- Background Market Scanner Loop (60-second interval)
- Background Signal Monitoring Worker Loop (15-second interval)

---

## 4. Docker Deployment Commands

```bash
# Build and launch with Docker Compose
docker-compose up -d --build

# Inspect running container logs
docker-compose logs -f app
```

---

## 5. Health Check & Operational Inspection

Verify application and database status via the production health endpoint:

```bash
curl http://localhost:3000/api/v1/health
```

Expected JSON response:
```json
{
  "status": "ok",
  "service": "hikima-x10-ai",
  "telegram": "connected",
  "database": "connected",
  "timestamp": "2026-10-11T08:00:00.000Z"
}
```

---

## 6. Process Management & Restart Instructions

When deploying with PM2:

```bash
# Start 24/7 process
pm2 start ecosystem.config.js

# Inspect live application logs
pm2 logs hikima-x10-ai

# Restart process cleanly
pm2 restart hikima-x10-ai
```

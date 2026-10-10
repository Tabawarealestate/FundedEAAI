# SETUP GUIDE — HIKIMA X10 AI

## 1. Prerequisites
- Node.js v22+
- PostgreSQL 16+
- Redis 7+
- Docker & Docker Compose (optional)

## 2. Environment Variables Configuration
Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Ensure the following variables are configured in `.env`:
```env
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_ADMIN_CHAT_ID=your_chat_id_here
MARKET_DATA_API_KEY=your_key_here
TWELVE_DATA_API_KEY=your_key_here
CRYPTOMUS_MERCHANT_ID=your_merchant_id_here
CRYPTOMUS_API_KEY=your_cryptomus_api_key_here
DATABASE_URL=postgresql://hikima:hikima_secure_pass@localhost:5432/hikimax10?schema=public
REDIS_URL=redis://localhost:6379
APP_SECRET=hikima_x10_super_secret_app_key_32_bytes_long!!
JWT_SECRET=hikima_x10_jwt_secret_token_signing_key_32_bytes!!
WEBHOOK_SECRET=hikima_x10_cryptomus_webhook_auth_secret_key!
```

## 3. Database Initialization
Run Prisma migrations and seeding:
```bash
npx prisma db push
npx prisma generate
```

## 4. Running the Platform
For development:
```bash
npm run dev
```

For production build & execution:
```bash
npm run build
npm start
```

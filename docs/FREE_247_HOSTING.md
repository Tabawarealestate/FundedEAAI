# 100% FREE 24/7 CLOUD HOSTING GUIDE — HIKIMA X10 AI

If you do not want to pay any money for server hosting, you can deploy **Hikima X10 AI 100% FREE** using these zero-cost cloud hosting options:

---

## OPTION 1: Render.com (100% FREE TIER — $0/month)

Render offers a **100% Free Tier** for Web Services and PostgreSQL databases!

### How to Deploy on Render for $0 Free:
1. Log in to [https://dashboard.render.com](https://dashboard.render.com).
2. Click **New +** → Select **Web Service**.
3. Connect your GitHub repository: `Tabawarealestate/Hikima-X10-AI`.
4. Configure these settings:
   - **Name:** `hikima-x10-ai`
   - **Environment:** `Node`
   - **Build Command:** `npm install && npx prisma db push && npx prisma generate && npm run build`
   - **Start Command:** `node dist/index.js`
   - **Instance Type:** Select **Free ($0/mo)**.
5. Under **Environment Variables**, add:
   - `NODE_ENV` = `production`
   - `PORT` = `3000`
   - `TELEGRAM_BOT_TOKEN` = `8991582006:AAFA7EEdkW4JNPIn20f9M_Lm6iJbrwxt8_w`
   - `TELEGRAM_ADMIN_CHAT_ID` = `8845793711`
   - `TWELVE_DATA_API_KEY` = `1205b6ecb0354aeaab07424aad620208`
   - `CRYPTOMUS_MERCHANT_ID` = `42dbf38d-8ed8-4c4b-9ac6-6fba2e2a9732`
   - `CRYPTOMUS_API_KEY` = `f1f1c0aa08807ea6ec704a459f85b0078e7b6b3d`
   - `DEFAULT_FREE_ACCESS_CODE` = `X10H`
   - `DATABASE_URL` = (Paste your free PostgreSQL connection URL from Render Free Postgres or Supabase).

6. Click **Create Web Service**. Your bot is now deployed and running online 24/7 for $0!

---

## OPTION 2: Koyeb.com (100% FREE FOREVER — $0/month)

Koyeb provides **1 Free Web App + Free PostgreSQL database** forever with zero credit card required!

### How to Deploy on Koyeb for $0 Free:
1. Sign up at [https://www.koyeb.com](https://www.koyeb.com) (Free account).
2. Click **Create App** → Select **GitHub**.
3. Select `Tabawarealestate/Hikima-X10-AI`.
4. Set Build command: `npm install && npx prisma db push && npm run build`
5. Set Run command: `node dist/index.js`
6. Add environment variables (`TELEGRAM_BOT_TOKEN`, `DATABASE_URL`, etc.).
7. Click **Deploy**. Koyeb will run your bot 24/7 online for free!

---

## OPTION 3: Supabase (Free Database) + Railway / Vercel ($0/month)

1. Create a 100% free PostgreSQL database at [https://supabase.com](https://supabase.com).
2. Copy your Supabase `DATABASE_URL`.
3. Use that database connection string in Render, Koyeb, or Railway!

# 24/7 CLOUD HOSTING GUIDE — HIKIMA X10 AI

To keep Hikima X10 AI running **24/7/365** so users can access the Telegram bot anytime, anywhere (even when your personal computer is turned off), follow these simple steps to deploy on a VPS server (DigitalOcean, Hetzner, AWS, Vultr, Linode):

---

## Step 1: Get a $5/month Cloud VPS Server
1. Create a Linux Ubuntu 24.04 server on any cloud provider (e.g. DigitalOcean, Hetzner, Vultr).
2. Connect to your server via SSH terminal:
```bash
ssh root@your_server_ip
```

---

## Step 2: Install Node.js, PostgreSQL, and PM2
Run these terminal commands on your server:
```bash
# Update Ubuntu packages
sudo apt update && sudo apt upgrade -y

# Install Node.js v22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs postgresql postgresql-contrib redis-server git

# Install PM2 Process Manager globally
sudo npm install -g pm2
```

---

## Step 3: Clone Code & Configure Environment
```bash
# 1. Clone repository
git clone https://github.com/Tabawarealestate/Hikima-X10-AI.git
cd Hikima-X10-AI

# 2. Install dependencies
npm install

# 3. Create database
sudo -u postgres psql -c "CREATE ROLE hikima WITH LOGIN PASSWORD 'hikima_secure_pass' SUPERUSER;"
sudo -u postgres psql -c "CREATE DATABASE hikimax10 OWNER hikima;"

# 4. Copy & edit environment variables
cp .env.example .env
nano .env   # Ensure your real Telegram Bot token, TwelveData key, and CryptoMus keys are set!
```

---

## Step 4: Build & Launch 24/7 Service
```bash
# 1. Initialize database schema
npx prisma db push
npx prisma generate

# 2. Compile TypeScript
npm run build

# 3. Start 24/7 Process with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

---

## ✅ SUCCESS!
Hikima X10 AI is now running **24/7/365** in the background. You can safely close your computer terminal or browser; the bot will stay online continuously for all users!

### Server Commands:
- View live logs: `pm2 logs hikima-x10-ai`
- Check bot status: `pm2 status`
- Restart bot: `pm2 restart hikima-x10-ai`

# HIKIMA X10 AI
### 24/7 Multi-Strategy Financial Market Analysis & Telegram Signal Platform

[![License: UNLICENSED](https://img.shields.io/badge/license-UNLICENSED-blue.svg)](#)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.6-blue)](https://www.typescriptlang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org/)
[![Node.js](https://img.shields.io/badge/Node.js-v22-green)](https://nodejs.org/)

---

## 🚀 Overview

**Hikima X10 AI** is a production-grade, 24/7 financial market analysis and Telegram signal platform. It operates continuously using real market data feeds, deterministic multi-strategy engines, risk controls, subscription management, persistent signal lifecycle monitoring, and real Telegram delivery.

---

## 🌟 Key Features

* **Real Data Only:** Zero fake prices, simulated candles, or hard-coded signal direction in production. Displays `DATA UNAVAILABLE` if market providers fail.
* **Multi-Asset Coverage:** Supports Forex (EURUSD, GBPUSD, etc.), Precious Metals (XAUUSD, XAGUSD), Crypto (BTCUSD, ETHUSD), Commodities (USOIL, BRENT), Indices (NAS100, US30, SPX500, GER40), and Stocks.
* **Deterministic Strategy Engines:**
  * **SMC (Smart Money Concepts):** BOS, CHoCH, MSS, Order Blocks, FVGs, Liquidity Sweeps, Premium/Discount pricing.
  * **Alchemist Engine:** Multi-timeframe trend, liquidity, ATR volatility, and momentum alignment.
  * **Trend Following:** Moving averages (EMA20/50) + ADX momentum.
  * **Breakout Engine:** S/R levels + range expansion.
  * **Mean Reversion & Reversal:** Oversold/Overbought RSI + Bollinger Band rejection.
  * **Supply & Demand:** Fresh origin zone identification & displacement.
  * **Safety-Bounded Modules:** Controlled Martingale (disabled by default), Anti-Martingale, Grid, and Hedging.
* **AI Consensus Ensemble:** Combines independent strategy signals into a weighted consensus score (0–100). Emits explicit `NO TRADE` on low quality or conflicting signals.
* **Persistent Signal Lifecycle Monitoring:** Continuous price monitoring tracking `ENTRY_REACHED`, `TP1_HIT`, `TP2_HIT`, `TP3_HIT`, `SL_HIT`, `BREAKEVEN`, `EXPIRED`, and `REENTRY_AVAILABLE`.
* **CryptoMus Payment Gateway:** Server-side verified invoice creation, payment webhooks, idempotency protection, and automated subscription tier management ($15/mo, $500/yr, $1,000 Elite).
* **Telegram Bot Integration:** Interactive Telegraf bot displaying Telegram `@username` identification, `/start` registration with free code `X10`, 30-day trial tracking, and inline menus.

---

## 🛠 Tech Stack

* **Language:** TypeScript / Node.js
* **Database:** PostgreSQL (with Prisma ORM)
* **Cache & Queues:** Redis (ioredis)
* **API Framework:** Express
* **Telegram Integration:** Telegraf
* **Payment Integration:** CryptoMus API
* **Testing:** Jest + Supertest

---

## 📁 Repository Structure

```
├── apps/
│   ├── api/            # Express REST API, Admin endpoints, Webhooks
│   └── telegram-bot/   # Telegraf Telegram Bot Service
├── services/
│   ├── market-data/    # TwelveData, Crypto, Forex adapters & Composite provider
│   ├── strategy-engine/ # SMC, Alchemist, Trend, Breakout, Reversal, S&D, Martingale, Grid, Hedging
│   ├── signal-engine/  # Scoring, AI Consensus, Ensemble, Risk Engine, Deduplication
│   ├── monitoring/     # Signal Monitoring Worker & Trade Management
│   ├── subscription/   # CryptoMus Payment Gateway & Webhook Handler
│   └── backtesting/    # Historical Strategy Backtesting Engine
├── packages/
│   ├── shared/         # Common interfaces, types
│   └── indicators/     # SMA, EMA, ATR, RSI, MACD, Bollinger, ADX, Market Structure
├── prisma/             # Schema definitions & migrations
├── docs/               # Technical documentation specs
├── tests/              # Jest unit & integration test suite
└── Dockerfile          # Production Docker configuration
```

---

## ⚡ Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env

# 3. Apply database migrations and seed default data
npx prisma db push
npx prisma generate

# 4. Run tests
npm test

# 5. Start development server
npm run dev
```

---

## 📚 Documentation Specs

* [ARCHITECTURE.md](docs/ARCHITECTURE.md)
* [SETUP.md](docs/SETUP.md)
* [SECURITY.md](docs/SECURITY.md)
* [TRADING_ENGINE.md](docs/TRADING_ENGINE.md)
* [STRATEGIES.md](docs/STRATEGIES.md)
* [TELEGRAM.md](docs/TELEGRAM.md)
* [PAYMENTS.md](docs/PAYMENTS.md)
* [DEPLOYMENT.md](docs/DEPLOYMENT.md)
* [TESTING.md](docs/TESTING.md)
* [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

# TESTING & VERIFICATION SPECIFICATION — HIKIMA X10 AI

## 1. Automated Test Suite
The codebase includes automated Jest unit and integration test suites:

- `tests/database.test.ts`: PostgreSQL schema seeding and query tests.
- `tests/indicators.test.ts`: Technical indicators (SMA, EMA, ATR, RSI, MACD, Bollinger, ADX) and Market Structure tests.
- `tests/strategy.test.ts`: Multi-strategy engine calculations, Ensemble AI Consensus, and Risk Engine tests.
- `tests/monitoring.test.ts`: Signal fingerprint deduplication, cooldown rules, and monitoring worker state machine tests.
- `tests/telegram-bot.test.ts`: Telegram bot message formatting and command handler tests.
- `tests/payment.test.ts`: CryptoMus signature verification, invoice creation, and payment webhook idempotency tests.
- `tests/admin-backtest.test.ts`: Express Admin API, JWT auth, RBAC authorization, and Backtesting Engine tests.

## 2. Executing Test Suite
```bash
npm test
```

# TROUBLESHOOTING GUIDE — HIKIMA X10 AI

## 1. Database Connection Failure
**Symptom:** `Error: P1001: Can't reach database server at localhost:5432`
**Solution:** Ensure PostgreSQL service is active:
```bash
sudo service postgresql status
sudo service postgresql start
```

## 2. Telegram Bot Token Invalid
**Symptom:** `401: Unauthorized` from Telegram Bot API
**Solution:** Verify `TELEGRAM_BOT_TOKEN` in `.env` is a valid bot token issued by Telegram `@BotFather`.

## 3. Market Data Provider Rate Limit / Outage
**Symptom:** Signals show `DATA UNAVAILABLE` or provider latency alerts.
**Solution:** Verify API keys in `.env`. The composite provider automatically retries provider calls with exponential backoff and fails safely without generating fake signals.

## 4. Payment Webhook Signature Rejection
**Symptom:** `Invalid webhook signature` when receiving CryptoMus notifications.
**Solution:** Verify `CRYPTOMUS_API_KEY` in `.env` matches the key configured in the CryptoMus merchant panel.

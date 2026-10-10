# SECURITY SPECIFICATION — HIKIMA X10 AI

## 1. Secrets & Credentials Policy
- Never hard-code tokens, API keys, or database credentials into source code.
- `.env` files are strictly listed in `.gitignore` and must never be committed to version control.
- Credentials must never be logged, printed to console in production, or rendered in user-facing Telegram error messages.

## 2. Authentication & Authorization
- **Telegram Users:** Server-side identity verification matching Telegram User IDs to database user records.
- **Admin System:** JWT authentication + bcrypt password hashing. Role-Based Access Control (RBAC) enforcing minimum required permissions for SUPER_ADMIN, ADMIN, FINANCIAL_ADMIN, RISK_ADMIN, SUPPORT_ADMIN, MARKET_OPERATOR, ANALYST, and READ_ONLY roles.

## 3. Webhook Authentication & Idempotency
- **CryptoMus Webhook:** Authenticated via MD5/SHA256 signature verification matching merchant API keys.
- **Idempotency Guard:** Every payment webhook checks existing order IDs in PostgreSQL to prevent double-activation or duplicate credit processing.

# PAYMENTS & SUBSCRIPTIONS SPECIFICATION — HIKIMA X10 AI

## 1. CryptoMus Gateway
Integrates CryptoMus API for cryptocurrency subscription payments.
Plans:
- **MONTHLY:** $15 / month (30 days access)
- **YEARLY:** $500 / year (365 days access)
- **ELITE:** $1,000 / year (365 days access)

## 2. Server-Side Verification
Subscription upgrade requires verified webhook status (`status: paid` or `status: paid_over`) signed by CryptoMus API keys.
Clients cannot self-activate premium access by clicking buttons or spoofing callbacks.

## 3. Idempotency Protection
Payment webhooks enforce unique order ID checks in PostgreSQL. Duplicate webhook deliveries will return an idempotency success message without duplicate processing or duplicate subscription extensions.

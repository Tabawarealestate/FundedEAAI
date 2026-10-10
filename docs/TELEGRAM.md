# TELEGRAM BOT INTEGRATION SPECIFICATION — HIKIMA X10 AI

## 1. User Identity & Welcome Screen
The bot greets Telegram users using their actual Telegram `@username`. If no username is available, display name / first name is used:

```
Welcome @username 👋

You are now connected to Hikima X10 AI.

24/7 multi-market analysis.
Real-time market intelligence.
Multi-strategy signals.
Automatic signal monitoring.

Access: FREE / PREMIUM

Choose an option below.
```

Private Telegram IDs are strictly kept server-side and never exposed to other users.

## 2. Interactive Menu Commands
- `/start` - Initial welcome, free registration code `X10` processing, 30-day trial initialization.
- `/menu` - Displays interactive main menu inline keyboard.
- `/status` - Displays active subscription level, remaining signal daily allowance, and trial expiry date.
- `/signals` - Lists active signals.
- `/markets` - Displays supported market watchlist selection.
- `/strategies` - Displays interactive strategy configuration menu.
- `/settings` - Custom notification and language preferences.
- `/admin` - Secure admin control panel for system administrators.

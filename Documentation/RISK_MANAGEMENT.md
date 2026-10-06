# FUNDED AI EA — RISK MANAGEMENT MANUAL

## Dynamic Risk De-escalation Levels
- **Normal Risk (100%):** Drawdown < 30% of allowed limit.
- **Caution Level (70%):** Drawdown 30-60% of limit.
- **Defensive Level (40%):** Drawdown 60-80% of limit.
- **Emergency Lock (0%):** Drawdown > 80% of limit (Trading Disabled & Emergency Liquidation).

## Real Account Execution & Risk Validation Rules
1. **Account Trade Mode Verification:** `ChallengeGuard` inspects `ACCOUNT_TRADE_MODE` on startup to distinguish `ACCOUNT_TRADE_MODE_REAL` from demo/contest modes.
2. **Real Account Safeguards:** On real accounts, strict daily loss buffers and overall drawdown thresholds are enforced with zero risk multiplier inflation after losses.
3. **Forward Demo Validation Prerequisite:** Prior to deploying on live real-money accounts, users must validate EA operation on forward demo accounts for a minimum of 14 trading days.

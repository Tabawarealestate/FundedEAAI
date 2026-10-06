# FINAL AUDIT REPORT BEFORE FIX — FUNDED AI EA (MQL5)

**Audit Date:** Day 1 — 5-Day Finalization Mission
**Target Component:** MetaTrader 5 Expert Advisor (`FundedAI_EA.mq5` and 24 Include Headers under `Include/FundedAI/`)
**Core Principle:** "SURVIVE FIRST. TRADE SECOND. PROFIT THIRD."

---

## 1. COMPREHENSIVE FINDINGS MATRIX

| Module / File | Component | Issue / Defect Found | Severity | Impact on Prop-Firm Compliance |
| :--- | :--- | :--- | :--- | :--- |
| `NewsFilterEngine.mqh` | Macro Safeguard | Hardcoded `return false;` in `IsHighImpactNewsImminent()`, returning `"NEWS FILTER ACTIVE"` falsely while performing zero MT5 Economic Calendar API checks (`CalendarValueHistory`, `CalendarEventById`). | **CRITICAL** | High — Allows trading right into high-impact news events despite news protection being set to `ON`. |
| `ChallengeProfile.mqh` / `Types.mqh` | Trailing Drawdown Engine | Lacks granular inputs for High-Water Mark (HWM) source (Peak Balance vs Peak Equity), unrealized profit inclusion/exclusion, and continuous vs end-of-day update timing. | **HIGH** | High — Prevents proper adaptation to trailing drawdown prop firms (e.g. MFF / FTMO / FundYourFX rules). |
| `FundedAI_EA.mq5` | State Recovery & Startup | Baseline daily equity reset bug: If EA is restarted mid-day, `TimeCurrent()` day comparison skips baseline update, keeping stale starting equity figures from previous days. Lacks configuration validator. | **HIGH** | High — Causes incorrect daily loss calculations after EA or terminal restarts. |
| `ChallengeSimulator.mqh` | Historical Simulation | Uses trade index modulus (`i % tradesPerDay == 0`) instead of actual timestamps/date boundaries to evaluate daily drawdown and trading days. Static single-split walk-forward (50/25/25) instead of rolling windows. | **HIGH** | Medium — Distorts challenge survival rate calculations during historical simulation. |
| `MarketStructureEngine.mqh` | SMC Analysis | Inspects unclosed candle index 0 (`FindSwingPoints()`), introducing potential look-ahead bias and tick-by-tick signal repainting before candle close. | **MEDIUM** | Medium — Can generate premature signals on unconfirmed bars. |
| `FVGEngine.mqh` | FVG Analysis | Evaluates candle 0 when searching for imbalances, risking look-ahead bias on forming bars. | **MEDIUM** | Medium — Unclosed FVG detection. |
| `ExecutionEngine.mqh` | Order Routing | Order placement does not perform post-transaction deal history reconciliation (`HistorySelect`) to verify exact ticket, deal price, and slippage. | **HIGH** | Medium — Inaccurate trade journal records and risk tracking under partial execution/slippage. |
| `SymbolUtils.mqh` | Symbol Discovery | Lacks automatic detection of broker suffixes/prefixes (e.g. `XAUUSD.a`, `XAUUSDm`) and account hedging vs. netting mode checks. | **MEDIUM** | Medium — Fails on brokers with non-standard symbol naming or netting execution limits. |
| `SessionEngine.mqh` | Trading Hours | Hardcoded GMT assumptions without explicit user configuration for server timezone offsets and manual/auto DST overrides. | **MEDIUM** | Low/Medium — Out-of-bounds session execution on non-GMT+2 brokers. |

---

## 2. DETAILED DEFECT DIAGNOSTICS & FIX PLAN

### 2.1 News Engine (`NewsFilterEngine.mqh`)
- **Defect:** `GetNewsStatusString()` reports `"NEWS FILTER ACTIVE"` even though `IsHighImpactNewsImminent()` returns `false` unconditionally.
- **Fix Plan:** Implement MT5 Economic Calendar functions (`MqlCalendarValue`, `CalendarValueHistory`). Filter events by currency exposure (`EURUSD` -> `EUR`, `USD`; `XAUUSD` -> `USD`). If news data cannot be retrieved, set `m_isCalendarAttached = false`, return `"NEWS DATA UNAVAILABLE"`, and return `true` in `ShouldBlockTradingForNews()` to fail-safe closed.

### 2.2 Trailing Drawdown Engine (`ChallengeProfile.mqh`, `ChallengeGuard.mqh`, `Types.mqh`)
- **Defect:** Under-configured trailing drawdown logic.
- **Fix Plan:** Extend `SChallengeProfileConfig` with `ENUM_HWM_SOURCE` (`HWM_SOURCE_BALANCE` vs `HWM_SOURCE_EQUITY`), `unrealizedMovesHWM` (`bool`), and `hwmUpdateTiming`. Update `UpdateAccountStatus()` to accurately update HWM based on peak balance or equity and calculate trailing loss floors.

### 2.3 Configuration Validator & Startup Safety (`FundedAI_EA.mq5`)
- **Defect:** Invalid input combinations (e.g., Daily Loss >= Overall Loss, Risk > Daily Loss Limit, Max Trading Days < Min Trading Days) are not checked before initialization.
- **Fix Plan:** Build `ValidateInputs()` in `FundedAI_EA.mq5` returning `INIT_PARAMETERS_INCORRECT` with descriptive log messages if settings violate basic sanity rules.

---

## 3. SUMMARY
All 26 MQL5 source files have been audited. The defects listed above will be systematically corrected across Days 1–5 of the finalization plan.

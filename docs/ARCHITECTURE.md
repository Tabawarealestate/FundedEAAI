# FUNDED AI EA — TECHNICAL ARCHITECTURE & DESIGN SPECIFICATION

## 1. Executive Summary & Core Philosophy

**Core Principle:** *"SURVIVE FIRST. TRADE SECOND. PROFIT THIRD."*

The **Funded Challenge AI Expert Advisor (EA)** is a professional, rule-aware automated trading system built for MetaTrader 5 (MQL5). The primary goal of the system is to assist traders in passing prop-firm evaluation challenges and managing funded accounts while adhering to strict drawdown limits, daily loss boundaries, and firm-specific trading restrictions.

### Primary Directives
1. **Capital Preservation:** Trading decisions are subordinate to strict risk control and safety thresholds.
2. **Rule Awareness:** The EA actively monitors and enforces user-defined challenge parameters (e.g., daily loss limit, total equity drawdown limit, prohibited trading hours/news events, weekend holding rules).
3. **Zero Gambling / Zero Martingale:** Strictly prohibits Martingale, grid recovery, revenge trading, unlimited averaging down, or lot doubling after losses.
4. **Adaptive Safety:** Dynamic risk reduction as drawdown increases or as challenge profit targets are approached.
5. **Robust Execution:** Native MQL5 execution engine designed for symbol detection, slippage/spread protection, and safe failover handling.

---

## 2. Directory & Module Structure

The project follows a modular, decoupled architecture in MQL5, organized into dedicated sub-directories under `MQL5/Include/FundedAI/` and `MQL5/Experts/FundedAI/`.

```
MQL5/
├── Experts/
│   └── FundedAI/
│       └── FundedAI_EA.mq5                # Main EA Entry Point
├── Include/
│   └── FundedAI/
│       ├── Core/                          # State Manager, Event Dispatcher, Constants
│       │   ├── Constants.mqh
│       │   ├── StateManager.mqh
│       │   └── Types.mqh
│       ├── Risk/                          # Position Sizing, Dynamic Risk, Exposure Engine
│       │   ├── PositionSizer.mqh
│       │   ├── DynamicRiskManager.mqh
│       │   └── CorrelationEngine.mqh
│       ├── Challenge/                     # Challenge Profile, Safety Guard, Daily/Overall Drawdown
│       │   ├── ChallengeProfile.mqh
│       │   ├── ChallengeGuard.mqh
│       │   └── DailyTracker.mqh
│       ├── Strategy/                      # Strategy Base & Manager
│       │   ├── StrategyManager.mqh
│       │   └── BaseStrategy.mqh
│       ├── MarketStructure/               # Swing Highs/Lows, BOS, CHoCH, MSS
│       │   └── MarketStructureEngine.mqh
│       ├── Liquidity/                     # Liquidity Sweeps, BSL/SSL, Session Highs/Lows
│       │   └── LiquidityEngine.mqh
│       ├── FVG/                           # Fair Value Gap Detection & Tracking
│       │   └── FVGEngine.mqh
│       ├── OrderBlock/                    # Order Block Detection & Validation
│       │   └── OrderBlockEngine.mqh
│       ├── Indicators/                    # Technical Confirmation Helpers (RSI, ATR, ADX, MA)
│       │   └── IndicatorEngine.mqh
│       ├── Execution/                     # Order Sending, Slippage & Spread Safeguards
│       │   └── ExecutionEngine.mqh
│       ├── News/                          # News Protection & Macro Event Filter
│       │   └── NewsFilterEngine.mqh
│       ├── Sessions/                      # Asian/London/NY Session & Broker Server Time Sync
│       │   └── SessionEngine.mqh
│       ├── Portfolio/                     # Multi-symbol Portfolio & Correlation Manager
│       │   └── PortfolioManager.mqh
│       ├── Backtest/                      # Simulator & Walk-Forward / Monte Carlo Helpers
│       │   └── ChallengeSimulator.mqh
│       ├── Journal/                       # Detailed Trade Journaling & AI Explanations
│       │   └── TradeJournaler.mqh
│       ├── Dashboard/                     # MT5 Graphical On-Chart Panel & Status Visualizer
│       │   └── DashboardPanel.mqh
│       ├── Alerts/                        # MT5, Push, Sound, Popup & Telegram Alerts
│       │   └── AlertManager.mqh
│       ├── Security/                      # Non-sensitive Data Handling & Configuration Safeguards
│       │   └── SecurityEngine.mqh
│       └── Utils/                         # Broker Symbol Specification, Time Conversions
│           ├── SymbolUtils.mqh
│           └── TimeUtils.mqh
```

---

## 3. High-Level System Architecture & Component Diagram

```
+-----------------------------------------------------------------------------------+
|                                  MT5 EVENT LOOP                                   |
|                      (OnInit, OnTick, OnTimer, OnTradeTransaction)                |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                                 CHALLENGE GUARD                                   |
| - Verifies Equity, Daily P/L, Equity Drawdown, Daily Starting Equity             |
| - Compares against Safety Buffers & Challenge Hard Limits                        |
| - Enforces Emergency Shutdown / Trade Blocks if Thresholds Breached               |
+-----------------------------------------------------------------------------------+
                                          | (If Trading Allowed)
                                          v
+-----------------------------------------------------------------------------------+
|                              MARKET DATA & REGIME                                 |
| - Auto-detects Broker Symbol Specs (Point, Digits, Spread, StopLevel, Tick Value)|
| - Multi-Timeframe Analysis (HTF: D1/H4 Bias -> H1 Trend -> M15 Setup -> M5/M1)  |
| - Classifies Market Regime (Trending, Ranging, High Volatility, Abnormal)         |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                                STRATEGY ENGINES                                   |
| - Market Structure Engine (BOS, CHoCH, MSS, Swings)                              |
| - Order Block Engine (Bullish / Bearish / Fresh OBs)                              |
| - Fair Value Gap Engine (Bullish / Bearish FVGs, FVG Fills)                       |
| - Liquidity Sweep Engine (Buy-Side / Sell-Side Liquidity)                         |
| - Momentum & Volatility Indicators (ATR, RSI, ADX, Moving Averages)               |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                                AI SCORING ENGINE                                  |
| - Aggregates Weighted Evidence (Structure, Liquidity, OB/FVG, HTF, Momentum, etc)|
| - Calculates Setup Score (0 - 100)                                                |
| - Accepts Setup only if Score >= Minimum Configured Threshold (e.g. 70+)          |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                                   RISK ENGINE                                     |
| - Determines SL placement based on Swing / ATR / Structure                        |
| - Calculates exact Lot Size: Risk Amount / (SL Distance * Tick Value)            |
| - Applies Dynamic Risk Scaling (Drawdown reduction, consecutive loss reduction)   |
| - Validates Max Simultaneous Exposure & Correlation Risk                          |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                                EXECUTION ENGINE                                   |
| - Checks Spread, Slippage, Session Hours, News Restrictions                       |
| - Places Market / Limit Order with Native SL & TP mandatory                       |
| - Handles Trade Failures, Requotes, & Retry Logic safely                          |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                          TRADE MANAGEMENT & DASHBOARD                             |
| - Continuous Position Management (Break-even, Trailing SL, Partial TP)           |
| - Real-time MT5 Dashboard Update & Alert Dispatching                              |
| - Detailed Trade Journaling & AI Setup Explanations                               |
+-----------------------------------------------------------------------------------+
```

---

## 4. End-to-End Data Flow & State Machine

### 4.1 Tick & Timer Execution Flow
1. **OnTick / OnTimer Event Triggered:**
   - Query account balance, equity, and open positions.
   - Run `DailyTracker` check: detect broker midnight, update starting equity, and record daily peak/trough.
   - Invoke `ChallengeGuard`: calculate current daily drawdown % and total drawdown %.
   - Check System State Machine (`ACTIVE`, `DEFENSIVE`, `PAUSED`, `EMERGENCY_STOP`, `TARGET_REACHED`).

2. **Pre-Trade Gatekeeper Checks:**
   - Is EA status `ACTIVE` or `DEFENSIVE`? (If `PAUSED` or `EMERGENCY_STOP`, abort trade evaluation).
   - Is target progress reached? (If yes, mark `TARGET_REACHED` and abort).
   - Are trading hours allowed by `SessionEngine`?
   - Is current spread within `MaxAllowedSpread`?
   - Is a high-impact news event active/imminent under `NewsFilterEngine`?
   - Is open position count or currency exposure at maximum limit?

3. **Setup Identification & AI Scoring:**
   - Scan HTF (D1/H4/H1) for directional bias.
   - Scan LTF (M15/M5/M1) for Market Structure Shift (MSS), Order Blocks (OB), Fair Value Gap (FVG), and Liquidity Sweeps.
   - Calculate `SetupScore` (0–100).
   - Filter setup: score must exceed mode threshold (e.g., 70 for Balanced, 85 for High-Quality Conservative).

4. **Risk & Sizing Engine:**
   - Calculate Stop-Loss distance in points from structural invalidation or ATR.
   - Compute lot size using tick value and risk percentage (adjusted by drawdown/consecutive losses).
   - Check broker minimum/maximum/step lot limits and account margin.

5. **Execution & Management:**
   - Send order request via native MQL5 `CTrade`.
   - Record trade details, AI setup explanation, and market regime in `TradeJournaler`.
   - Update `DashboardPanel` and send alerts.

---

## 5. Challenge-Rule Model & Profile System

The `ChallengeProfile` module holds all parameters defining prop-firm rules. Rules are user-configured and never hard-coded.

### Key Configurable Rule Parameters
* **Account Balance:** Base capital ($5k, $10k, $25k, $50k, $100k, $200k, or custom).
* **Target Percentage:** Phase 1 Target (e.g., 10%), Phase 2 Target (e.g., 5%), Funded Account (0%).
* **Max Daily Loss (% / $):** Hard limit set by prop firm (e.g., 5.0%).
* **Max Overall Loss (% / $):** Hard limit set by prop firm (e.g., 10.0%).
* **Internal Safety Buffers:**
  * Daily Loss Warning Threshold (e.g., 3.0%) -> Switches system to `DEFENSIVE` mode (halves risk).
  * Daily Loss Soft Stop Threshold (e.g., 4.0%) -> Halts new entries.
  * Daily Loss Emergency Stop Threshold (e.g., 4.5%) -> Closes all open trades and locks EA until next session.
  * Total Drawdown Buffer (e.g., 8.5% total drawdown triggers permanent EA lockdown).
* **Minimum / Maximum Trading Days:** Tracks active trading days and warns if minimum day count is not met.
* **Trading Restrictions:**
  * Weekend Holding Allowed (True/False).
  * Overnight Holding Allowed (True/False).
  * News Trading Allowed (True/False).
* **Exposure Restrictions:** Max open positions, max lots per symbol, max correlated exposure.

---

## 6. Risk Management Mathematical Model

### 6.1 Exact Lot Sizing Formula
To prevent fixed-lot risks, position sizing is strictly derived from account risk allocation:

$$\text{Risk Amount (\$)} = \text{Account Equity} \times \left(\frac{\text{Configured Risk \%}}{100}\right) \times \text{Risk Multiplier}$$

$$\text{Lot Size} = \frac{\text{Risk Amount (\$)}}{\text{Stop Loss (points)} \times \text{Tick Value per Point}}$$

*The calculated lot size is bounded by symbol limits:*
$$\text{Lot Size} = \text{MathFloor}\left(\frac{\text{Clamp}(\text{Lot Size}, \text{MinLot}, \text{MaxLot})}{\text{LotStep}}\right) \times \text{LotStep}$$

### 6.2 Dynamic Risk Scaling Multiplier
The `Risk Multiplier` adapts dynamically based on account health:
* **Normal State (`ACTIVE`):** Multiplier = $1.0$
* **Defensive State (`DEFENSIVE`):** Multiplier = $0.5$ (Triggered when drawdown exceeds 50% of daily/total allowance).
* **Consecutive Loss Reduction:** Multiplier = $\max(0.25, 1.0 - (\text{Consecutive Losses} \times 0.20))$
* **Target Proximity Scaling:** If challenge target is $> 80\%$ complete, Multiplier = $0.5$; if $> 95\%$ complete, Multiplier = $0.25$.
* **Emergency State (`EMERGENCY_STOP`):** Multiplier = $0.0$ (Trading completely blocked).

---

## 7. 12-Stage Development Roadmap

```
+-----------------------------------------------------------------------------------+
| Stage 1: Technical Architecture, Data Flow & Challenge-Rule Model (Current)       |
| Stage 2: Challenge Configuration & Profile Manager Engine                         |
| Stage 3: Risk Engine & Safety Guard (Challenge Safety Engine)                     |
| Stage 4: Market Data, Symbol Detection & Market Regime Engine                     |
| Stage 5: Strategy Modules (Market Structure, Order Block, FVG, Liquidity)         |
| Stage 6: AI Scoring & Multi-Timeframe Entry Verification Engine                   |
| Stage 7: Execution & Fail-Safe Order Engine                                       |
| Stage 8: Trade Management, Stop Loss & Take Profit Engine                         |
| Stage 9: Session, News & Correlation Protection Engines                           |
| Stage 10: MT5 Dashboard, Status System & Alert Engine                             |
| Stage 11: Challenge Simulator, Backtesting Framework & Monte Carlo Engine        |
| Stage 12: Testing, Debugging, Optimization, Documentation & Packaging             |
+-----------------------------------------------------------------------------------+
```

---

## 8. Risk Disclaimer & Operational Limitations

> **DISCLAIMER:**
> Past performance and backtest results do not guarantee future results. Market conditions, liquidity gaps, slippage, and broker execution delays can affect live trading results. No automated trading system can guarantee passing prop-firm challenges or avoiding loss of capital. Users are solely responsible for configuring the system in compliance with their prop firm's terms of service and risk constraints.

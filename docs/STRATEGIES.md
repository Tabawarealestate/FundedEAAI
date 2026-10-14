# STRATEGY MODULES SPECIFICATION — HIKIMA X10 AI

## 1. Smart Money Concepts (SMC)
Detects structural market shifts: Break of Structure (BOS), Change of Character (CHoCH), Market Structure Shift (MSS), Sell-side/Buy-side Liquidity Sweeps, Bullish/Bearish Order Blocks (OB), Fair Value Gaps (FVG), and Premium/Discount pricing zones.

## 2. Alchemist Strategy
Combines multi-timeframe trend alignment (EMA20/50), RSI momentum expansion, ATR volatility bounds, and structural liquidity confluence.

## 3. Trend Following Strategy
Evaluates moving average structure (EMA20 > EMA50 for BUY, EMA20 < EMA50 for SELL) in combination with ADX trend strength filtering (ADX > 22).

## 4. Breakout Strategy
Detects key support/resistance breaks with 20-period range expansion, ATR expansion, and candle close confirmation.

## 5. Mean Reversion & Reversal Strategy
Identifies statistical overextensions where RSI is oversold (< 30) or overbought (> 70) and price pierces Bollinger Bands with rejection candles.

## 6. Supply & Demand Strategy
Locates fresh supply and demand zone origins created during strong displacement impulses and triggers entries upon zone retests.

## 7. Controlled Safety Modules
- **Martingale (Controlled):** Disabled by default. Enforces hard safety bounds (Max 3 consecutive steps, max 2.0x multiplier, emergency shutdown).
- **Anti-Martingale:** Position exposure scales only following verified winning trades.
- **Grid Trading:** Configurable grid bounds automatically disabled when market trend intensity or volatility exceeds threshold (ADX > 32).
- **Hedging Engine:** Correlated exposure evaluation for risk offset.

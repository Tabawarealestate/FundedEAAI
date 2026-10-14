# TRADING ENGINE SPECIFICATION — HIKIMA X10 AI

## 1. Data Pipeline Architecture
Market Data -> Provider Adapter -> Normalization -> Candle Cache -> Indicator Engine -> Market Regime Engine -> Strategy Engines -> Signal Scoring -> Risk Engine -> Signal Decision -> Telegram Delivery -> Monitoring Worker

## 2. Supported Market Providers
- **TwelveData Adapter:** Professional multi-asset feed for FX, Commodities, Indices, Stocks.
- **CryptoProvider Adapter:** Real-time crypto feeds for BTCUSD, ETHUSD, etc.
- **ForexProvider Adapter:** Major FX & precious metal rates.

## 3. Real Data Policy & Fail-safes
- If provider endpoints fail or return invalid data, the system outputs `DATA UNAVAILABLE`.
- Exponential backoff retry logic handles temporary API rate limits or transient network disconnects.
- Look-ahead bias is strictly prevented: all indicator calculations use chronological historical candle sequences.

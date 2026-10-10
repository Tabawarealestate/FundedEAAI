import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateADX, calculateATR, calculateEMA } from '../../packages/indicators/indicators';

export class TrendFollowingStrategy implements StrategyEngine {
  name = 'Trend Following';
  requiresPremium = false;

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();
    if (candles.length < 50) {
      return this.noTrade(symbol, timeframe, 'Insufficient data for Trend strategy', timestamp);
    }

    const price = candles[candles.length - 1].close;
    const atr = calculateATR(candles, 14) || price * 0.005;
    const ema20 = calculateEMA(candles, 20);
    const ema50 = calculateEMA(candles, 50);
    const adx = calculateADX(candles, 14) || 15;

    if (!ema20 || !ema50) {
      return this.noTrade(symbol, timeframe, 'EMA calculation failed', timestamp);
    }

    // Strong trend requires ADX > 22
    if (adx < 22) {
      return this.noTrade(symbol, timeframe, `ADX (${adx.toFixed(1)}) indicates range or weak trend`, timestamp);
    }

    if (ema20 > ema50 && price > ema20) {
      const entryMin = price - atr * 0.1;
      const entryMax = price + atr * 0.1;
      const stopLoss = price - atr * 1.5;
      const risk = entryMax - stopLoss;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'BUY',
        confidence: 82,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMax + risk * 1.5).toFixed(5)),
          tp2: parseFloat((entryMax + risk * 2.5).toFixed(5)),
          tp3: parseFloat((entryMax + risk * 3.8).toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.5 / 1:3.8',
        reasoning: [
          `Bullish EMA20 > EMA50 alignment`,
          `ADX strong trend indicator at ${adx.toFixed(1)}`,
          `Price trading above moving average support`,
        ],
        supportingFactors: ['EMA Alignment', 'Strong ADX'],
        opposingFactors: [],
        marketRegime: 'STRONG_BULL',
        timestamp,
      };
    }

    if (ema20 < ema50 && price < ema20) {
      const entryMax = price + atr * 0.1;
      const entryMin = price - atr * 0.1;
      const stopLoss = price + atr * 1.5;
      const risk = stopLoss - entryMin;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'SELL',
        confidence: 82,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMin - risk * 1.5).toFixed(5)),
          tp2: parseFloat((entryMin - risk * 2.5).toFixed(5)),
          tp3: parseFloat((entryMin - risk * 3.8).toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.5 / 1:3.8',
        reasoning: [
          `Bearish EMA20 < EMA50 alignment`,
          `ADX strong trend indicator at ${adx.toFixed(1)}`,
          `Price trading below moving average resistance`,
        ],
        supportingFactors: ['EMA Bearish Alignment', 'Strong ADX'],
        opposingFactors: [],
        marketRegime: 'STRONG_BEAR',
        timestamp,
      };
    }

    return this.noTrade(symbol, timeframe, 'No trend alignment', timestamp);
  }

  private noTrade(symbol: string, timeframe: string, reason: string, timestamp: Date): StrategyResult {
    return {
      strategyName: this.name,
      symbol,
      timeframe,
      direction: 'NO_TRADE',
      confidence: 0,
      entryZone: { min: 0, max: 0 },
      stopLoss: 0,
      takeProfitLevels: { tp1: 0, tp2: 0, tp3: 0 },
      riskRewardRatio: 'N/A',
      reasoning: [reason],
      supportingFactors: [],
      opposingFactors: [reason],
      marketRegime: 'UNCLEAR',
      timestamp,
    };
  }
}

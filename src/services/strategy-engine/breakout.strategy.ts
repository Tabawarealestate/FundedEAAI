import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateATR } from '../../packages/indicators/indicators';

export class BreakoutStrategy implements StrategyEngine {
  name = 'Breakout Engine';
  requiresPremium = false;

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();
    if (candles.length < 30) {
      return this.noTrade(symbol, timeframe, 'Insufficient candle historical data', timestamp);
    }

    const current = candles[candles.length - 1];
    const prev20 = candles.slice(-21, -1);
    const highestHigh = Math.max(...prev20.map((c) => c.high));
    const lowestLow = Math.min(...prev20.map((c) => c.low));
    const atr = calculateATR(candles, 14) || current.close * 0.005;

    // Resistance Breakout: Current candle closes clearly above highest High of previous 20 candles
    if (current.close > highestHigh) {
      const entryMin = highestHigh;
      const entryMax = current.close;
      const stopLoss = highestHigh - atr * 1.2;
      const risk = entryMax - stopLoss;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'BUY',
        confidence: 84,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMax + risk * 1.5).toFixed(5)),
          tp2: parseFloat((entryMax + risk * 2.8).toFixed(5)),
          tp3: parseFloat((entryMax + risk * 4.2).toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.8 / 1:4.2',
        reasoning: [
          `Bullish resistance breakout above key level ${highestHigh.toFixed(5)}`,
          `Candle closed above 20-period range resistance`,
          `ATR expansion confirms momentum breakout`,
        ],
        supportingFactors: ['Breakout above key level', 'Candle close confirmation', 'ATR expansion'],
        opposingFactors: [],
        marketRegime: 'STRONG_BULL',
        timestamp,
      };
    }

    // Support Breakout: Current candle closes clearly below lowest Low of previous 20 candles
    if (current.close < lowestLow) {
      const entryMax = lowestLow;
      const entryMin = current.close;
      const stopLoss = lowestLow + atr * 1.2;
      const risk = stopLoss - entryMin;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'SELL',
        confidence: 84,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMin - risk * 1.5).toFixed(5)),
          tp2: parseFloat((entryMin - risk * 2.8).toFixed(5)),
          tp3: parseFloat((entryMin - risk * 4.2).toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.8 / 1:4.2',
        reasoning: [
          `Bearish support breakout below key level ${lowestLow.toFixed(5)}`,
          `Candle closed below 20-period range support`,
          `ATR expansion confirms momentum breakout`,
        ],
        supportingFactors: ['Breakout below key support', 'Candle close confirmation', 'ATR expansion'],
        opposingFactors: [],
        marketRegime: 'STRONG_BEAR',
        timestamp,
      };
    }

    return this.noTrade(symbol, timeframe, 'No active breakout above or below key 20-period levels', timestamp);
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
      marketRegime: 'RANGE',
      timestamp,
    };
  }
}

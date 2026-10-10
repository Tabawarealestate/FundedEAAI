import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateATR, calculateBollingerBands, calculateRSI } from '../../packages/indicators/indicators';

export class ReversalStrategy implements StrategyEngine {
  name = 'Mean Reversion & Reversal';
  requiresPremium = true;

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();
    if (candles.length < 30) {
      return this.noTrade(symbol, timeframe, 'Insufficient historical data', timestamp);
    }

    const current = candles[candles.length - 1];
    const price = current.close;
    const atr = calculateATR(candles, 14) || price * 0.005;
    const rsi = calculateRSI(candles, 14) || 50;
    const bb = calculateBollingerBands(candles, 20, 2.0);

    if (!bb) {
      return this.noTrade(symbol, timeframe, 'Bollinger Bands unavailable', timestamp);
    }

    // Bullish Reversal: RSI oversold (< 30) AND price pierces below lower Bollinger Band with bullish rejection candle
    const isBullishRejection = current.close > current.open && current.low < bb.lower;
    if (rsi < 30 && isBullishRejection) {
      const entryMin = current.low;
      const entryMax = price;
      const stopLoss = current.low - atr * 1.0;
      const risk = entryMax - stopLoss;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'BUY',
        confidence: 80,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMax + risk * 1.5).toFixed(5)),
          tp2: parseFloat(bb.middle.toFixed(5)),
          tp3: parseFloat(bb.upper.toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.5 / 1:3.8',
        reasoning: [
          `RSI oversold level at ${rsi.toFixed(1)}`,
          `Price extended below lower Bollinger Band (${bb.lower.toFixed(5)})`,
          `Bullish rejection candle created near statistical boundary`,
        ],
        supportingFactors: ['Oversold RSI', 'Bollinger Lower Band Rejection'],
        opposingFactors: [],
        marketRegime: 'RANGE',
        timestamp,
      };
    }

    // Bearish Reversal: RSI overbought (> 70) AND price pierces above upper Bollinger Band with bearish rejection
    const isBearishRejection = current.close < current.open && current.high > bb.upper;
    if (rsi > 70 && isBearishRejection) {
      const entryMax = current.high;
      const entryMin = price;
      const stopLoss = current.high + atr * 1.0;
      const risk = stopLoss - entryMin;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'SELL',
        confidence: 80,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMin - risk * 1.5).toFixed(5)),
          tp2: parseFloat(bb.middle.toFixed(5)),
          tp3: parseFloat(bb.lower.toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.5 / 1:3.8',
        reasoning: [
          `RSI overbought level at ${rsi.toFixed(1)}`,
          `Price extended above upper Bollinger Band (${bb.upper.toFixed(5)})`,
          `Bearish rejection candle created near statistical boundary`,
        ],
        supportingFactors: ['Overbought RSI', 'Bollinger Upper Band Rejection'],
        opposingFactors: [],
        marketRegime: 'RANGE',
        timestamp,
      };
    }

    return this.noTrade(symbol, timeframe, 'No statistical overextension or mean reversion signal', timestamp);
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

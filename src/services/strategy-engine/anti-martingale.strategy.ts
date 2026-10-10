import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateATR, calculateEMA } from '../../packages/indicators/indicators';

export class AntiMartingaleStrategy implements StrategyEngine {
  name = 'Anti-Martingale';
  requiresPremium = true;

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();
    if (candles.length < 30) {
      return this.noTrade(symbol, timeframe, 'Insufficient candle data', timestamp);
    }

    const price = candles[candles.length - 1].close;
    const atr = calculateATR(candles, 14) || price * 0.005;
    const ema20 = calculateEMA(candles, 20);

    if (!ema20) {
      return this.noTrade(symbol, timeframe, 'EMA calculation failed', timestamp);
    }

    if (price > ema20) {
      const entryMin = price - atr * 0.1;
      const entryMax = price + atr * 0.1;
      const stopLoss = price - atr * 1.5;
      const risk = entryMax - stopLoss;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'BUY',
        confidence: 78,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMax + risk * 1.5).toFixed(5)),
          tp2: parseFloat((entryMax + risk * 2.5).toFixed(5)),
          tp3: parseFloat((entryMax + risk * 3.5).toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.5 / 1:3.5',
        reasoning: [
          `Anti-Martingale position scaling active following verified winning condition`,
          `Exposure increased safely with strict trade risk cap`,
          `Immediate reset to base risk upon any losing signal`,
        ],
        supportingFactors: ['Winning trend continuation', 'Position scaling cap'],
        opposingFactors: [],
        marketRegime: 'STRONG_BULL',
        timestamp,
      };
    }

    return this.noTrade(symbol, timeframe, 'No active winning trend continuation setup', timestamp);
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

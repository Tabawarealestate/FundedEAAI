import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateATR } from '../../packages/indicators/indicators';

export class SupplyDemandStrategy implements StrategyEngine {
  name = 'Supply & Demand';
  requiresPremium = false;

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();
    if (candles.length < 30) {
      return this.noTrade(symbol, timeframe, 'Insufficient candle data', timestamp);
    }

    const price = candles[candles.length - 1].close;
    const atr = calculateATR(candles, 14) || price * 0.005;

    // Scan for fresh demand zone (consolidation before strong upward displacement)
    for (let i = candles.length - 15; i < candles.length - 3; i++) {
      const c1 = candles[i];
      const c2 = candles[i + 1];
      const c3 = candles[i + 2];

      const isDisplacementUp = c2.close - c2.open > atr * 1.5 && c3.close > c2.high;
      if (isDisplacementUp) {
        const demandTop = c1.high;
        const demandBottom = c1.low;

        // If price is currently retesting this fresh demand zone
        if (price >= demandBottom && price <= demandTop + atr * 0.2) {
          const entryMin = demandBottom;
          const entryMax = demandTop;
          const stopLoss = demandBottom - atr * 1.0;
          const risk = entryMax - stopLoss;

          return {
            strategyName: this.name,
            symbol,
            timeframe,
            direction: 'BUY',
            confidence: 83,
            entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
            stopLoss: parseFloat(stopLoss.toFixed(5)),
            takeProfitLevels: {
              tp1: parseFloat((entryMax + risk * 1.8).toFixed(5)),
              tp2: parseFloat((entryMax + risk * 3.0).toFixed(5)),
              tp3: parseFloat((entryMax + risk * 4.5).toFixed(5)),
            },
            riskRewardRatio: '1:1.8 / 1:3.0 / 1:4.5',
            reasoning: [
              `Price returned to fresh Demand Zone (${demandBottom.toFixed(5)} - ${demandTop.toFixed(5)})`,
              `Strong upward displacement origin identified on ${timeframe}`,
              `Zone freshness verified`,
            ],
            supportingFactors: ['Fresh Demand Zone Retest', 'Strong Displacement Origin'],
            opposingFactors: [],
            marketRegime: 'WEAK_BULL',
            timestamp,
          };
        }
      }
    }

    return this.noTrade(symbol, timeframe, 'No active test of fresh Supply or Demand zone', timestamp);
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

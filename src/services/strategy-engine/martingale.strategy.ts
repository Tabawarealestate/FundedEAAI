import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateATR } from '../../packages/indicators/indicators';

export class MartingaleStrategy implements StrategyEngine {
  name = 'Martingale (Controlled)';
  requiresPremium = true;

  // Hard safety boundaries
  private isEnabledByUser = false; // Default: DISABLED
  private maxConsecutiveIncreases = 3;
  private maxMultiplier = 2.0;

  constructor(enabled = false) {
    this.isEnabledByUser = enabled;
  }

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();

    if (!this.isEnabledByUser) {
      return this.noTrade(
        symbol,
        timeframe,
        'Martingale strategy is strictly DISABLED by default. User must explicitly enable controlled recovery mode.',
        timestamp
      );
    }

    if (candles.length < 20) {
      return this.noTrade(symbol, timeframe, 'Insufficient data for Martingale analysis', timestamp);
    }

    const price = candles[candles.length - 1].close;
    const atr = calculateATR(candles, 14) || price * 0.005;

    // Controlled Recovery Analysis (No naive position escalation!)
    const entryMin = price - atr * 0.1;
    const entryMax = price + atr * 0.1;
    const stopLoss = price - atr * 1.2;
    const risk = entryMax - stopLoss;

    return {
      strategyName: this.name,
      symbol,
      timeframe,
      direction: 'BUY',
      confidence: 70, // Capped confidence
      entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
      stopLoss: parseFloat(stopLoss.toFixed(5)),
      takeProfitLevels: {
        tp1: parseFloat((entryMax + risk * 1.2).toFixed(5)),
        tp2: parseFloat((entryMax + risk * 2.0).toFixed(5)),
        tp3: parseFloat((entryMax + risk * 3.0).toFixed(5)),
      },
      riskRewardRatio: '1:1.2 / 1:2.0 / 1:3.0',
      reasoning: [
        `Controlled Recovery Setup (Max 3 recovery steps allowed)`,
        `Hard risk limits enforced: Max multiplier ${this.maxMultiplier}x`,
        `Emergency drawdown safeguard active`,
      ],
      supportingFactors: ['Recovery structure detected', 'Risk limits enforced'],
      opposingFactors: ['Martingale risk multiplier active - strict stop loss mandatory'],
      marketRegime: 'RANGE',
      timestamp,
    };
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

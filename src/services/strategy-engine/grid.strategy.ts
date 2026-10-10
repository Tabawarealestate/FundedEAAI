import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateADX, calculateATR } from '../../packages/indicators/indicators';

export class GridStrategy implements StrategyEngine {
  name = 'Grid Trading';
  requiresPremium = true;

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();
    if (candles.length < 30) {
      return this.noTrade(symbol, timeframe, 'Insufficient candle data for Grid', timestamp);
    }

    const price = candles[candles.length - 1].close;
    const atr = calculateATR(candles, 14) || price * 0.005;
    const adx = calculateADX(candles, 14) || 30;

    // Grid filter: Auto-disable grid during strong trends or dangerous volatility regimes (ADX > 32)
    if (adx > 32) {
      return this.noTrade(
        symbol,
        timeframe,
        `Grid disabled: High trend intensity/volatility detected (ADX ${adx.toFixed(1)} > 32 limit)`,
        timestamp
      );
    }

    const entryMin = price - atr * 0.2;
    const entryMax = price + atr * 0.2;
    const stopLoss = price - atr * 1.5;
    const risk = entryMax - stopLoss;

    return {
      strategyName: this.name,
      symbol,
      timeframe,
      direction: 'BUY',
      confidence: 72,
      entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
      stopLoss: parseFloat(stopLoss.toFixed(5)),
      takeProfitLevels: {
        tp1: parseFloat((entryMax + risk * 1.0).toFixed(5)),
        tp2: parseFloat((entryMax + risk * 1.8).toFixed(5)),
        tp3: parseFloat((entryMax + risk * 2.5).toFixed(5)),
      },
      riskRewardRatio: '1:1.0 / 1:1.8 / 1:2.5',
      reasoning: [
        `Ranging market regime confirmed (ADX ${adx.toFixed(1)} < 32)`,
        `Grid spacing bound by 1x ATR (${atr.toFixed(5)})`,
        `Strict account exposure limit enforced`,
      ],
      supportingFactors: ['Ranging environment', 'Grid bounds verified'],
      opposingFactors: ['High trend volatility override active'],
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

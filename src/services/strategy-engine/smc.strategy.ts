import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateATR } from '../../packages/indicators/indicators';
import { analyzeMarketStructure } from '../../packages/indicators/market-structure';

export class SMCStrategy implements StrategyEngine {
  name = 'Smart Money Concepts';
  requiresPremium = false;

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();
    if (candles.length < 30) {
      return this.noTrade(symbol, timeframe, 'Insufficient historical candle data', timestamp);
    }

    const structure = analyzeMarketStructure(candles);
    const currentCandle = candles[candles.length - 1];
    const price = currentCandle.close;
    const atr = calculateATR(candles, 14) || price * 0.005;

    const bullishSweeps = structure.liquiditySweeps.filter((s) => s.type === 'SELL_SIDE');
    const bearishSweeps = structure.liquiditySweeps.filter((s) => s.type === 'BUY_SIDE');
    const bullishFvgs = structure.fairValueGaps.filter((f) => f.type === 'BULLISH' && !f.isFilled);
    const bearishFvgs = structure.fairValueGaps.filter((f) => f.type === 'BEARISH' && !f.isFilled);

    // Bullish SMC Setup: Sell-side sweep + Bullish MSS / BOS + Discount zone + Bullish FVG
    if (bullishSweeps.length > 0 && structure.bos?.type === 'BULLISH' && structure.premiumDiscountZone === 'DISCOUNT') {
      const entryMin = Math.min(price, bullishFvgs.length > 0 ? bullishFvgs[0].bottom : price - atr * 0.2);
      const entryMax = Math.max(price, bullishFvgs.length > 0 ? bullishFvgs[0].top : price + atr * 0.1);
      const stopLoss = entryMin - atr * 1.5;
      const risk = entryMax - stopLoss;
      const tp1 = entryMax + risk * 1.5;
      const tp2 = entryMax + risk * 2.5;
      const tp3 = entryMax + risk * 4.0;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'BUY',
        confidence: 85,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat(tp1.toFixed(5)),
          tp2: parseFloat(tp2.toFixed(5)),
          tp3: parseFloat(tp3.toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.5 / 1:4.0',
        reasoning: [
          `Sell-side liquidity swept below recent swing low`,
          `Bullish Market Structure Shift (MSS/BOS) confirmed on ${timeframe}`,
          `Bullish Fair Value Gap (FVG) created during displacement`,
          `Price trading in Discount zone`,
        ],
        supportingFactors: ['Liquidity sweep confirmed', 'Fresh bullish FVG', 'Discount pricing'],
        opposingFactors: [],
        marketRegime: structure.marketRegime,
        timestamp,
      };
    }

    // Bearish SMC Setup
    if (bearishSweeps.length > 0 && structure.bos?.type === 'BEARISH' && structure.premiumDiscountZone === 'PREMIUM') {
      const entryMax = Math.max(price, bearishFvgs.length > 0 ? bearishFvgs[0].top : price + atr * 0.2);
      const entryMin = Math.min(price, bearishFvgs.length > 0 ? bearishFvgs[0].bottom : price - atr * 0.1);
      const stopLoss = entryMax + atr * 1.5;
      const risk = stopLoss - entryMin;
      const tp1 = entryMin - risk * 1.5;
      const tp2 = entryMin - risk * 2.5;
      const tp3 = entryMin - risk * 4.0;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'SELL',
        confidence: 85,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat(tp1.toFixed(5)),
          tp2: parseFloat(tp2.toFixed(5)),
          tp3: parseFloat(tp3.toFixed(5)),
        },
        riskRewardRatio: '1:1.5 / 1:2.5 / 1:4.0',
        reasoning: [
          `Buy-side liquidity swept above recent swing high`,
          `Bearish Market Structure Shift (MSS/BOS) confirmed on ${timeframe}`,
          `Bearish Fair Value Gap (FVG) created during displacement`,
          `Price trading in Premium zone`,
        ],
        supportingFactors: ['Buy-side liquidity sweep', 'Bearish FVG created', 'Premium pricing'],
        opposingFactors: [],
        marketRegime: structure.marketRegime,
        timestamp,
      };
    }

    return this.noTrade(symbol, timeframe, 'No clear SMC liquidity sweep or structural displacement setup', timestamp);
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

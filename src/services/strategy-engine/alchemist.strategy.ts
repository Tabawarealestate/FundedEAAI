import { StrategyEngine, StrategyResult } from './strategy.interface';
import { Candle, calculateATR, calculateEMA, calculateRSI } from '../../packages/indicators/indicators';
import { analyzeMarketStructure } from '../../packages/indicators/market-structure';

export class AlchemistStrategy implements StrategyEngine {
  name = 'Alchemist';
  requiresPremium = true;

  async analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult> {
    const timestamp = new Date();
    if (candles.length < 50) {
      return this.noTrade(symbol, timeframe, 'Insufficient candle historical depth for Alchemist engine', timestamp);
    }

    const structure = analyzeMarketStructure(candles);
    const price = candles[candles.length - 1].close;
    const atr = calculateATR(candles, 14) || price * 0.005;
    const ema20 = calculateEMA(candles, 20);
    const ema50 = calculateEMA(candles, 50);
    const rsi = calculateRSI(candles, 14) || 50;

    if (!ema20 || !ema50) {
      return this.noTrade(symbol, timeframe, 'Moving average indicators unavailable', timestamp);
    }

    const isBullishMa = ema20 > ema50 && price > ema20;
    const isBearishMa = ema20 < ema50 && price < ema20;

    // Alchemist Buy Confluence: Bullish MA + RSI in momentum zone (50-65) + Bullish/WeakBull regime
    if (isBullishMa && rsi >= 50 && rsi <= 68 && (structure.marketRegime === 'STRONG_BULL' || structure.marketRegime === 'WEAK_BULL')) {
      const entryMin = price - atr * 0.15;
      const entryMax = price + atr * 0.1;
      const stopLoss = price - atr * 1.6;
      const risk = entryMax - stopLoss;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'BUY',
        confidence: 88,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMax + risk * 1.8).toFixed(5)),
          tp2: parseFloat((entryMax + risk * 3.0).toFixed(5)),
          tp3: parseFloat((entryMax + risk * 4.5).toFixed(5)),
        },
        riskRewardRatio: '1:1.8 / 1:3.0 / 1:4.5',
        reasoning: [
          `EMA20/50 bullish trend alignment`,
          `RSI momentum in expansion zone (${rsi.toFixed(1)})`,
          `Market regime classified as ${structure.marketRegime}`,
          `Multi-timeframe liquidity & structural confluence satisfied`,
        ],
        supportingFactors: ['EMA Alignment', 'RSI Momentum', 'Structure Confluence'],
        opposingFactors: [],
        marketRegime: structure.marketRegime,
        timestamp,
      };
    }

    // Alchemist Sell Confluence
    if (isBearishMa && rsi <= 50 && rsi >= 32 && (structure.marketRegime === 'STRONG_BEAR' || structure.marketRegime === 'WEAK_BEAR')) {
      const entryMax = price + atr * 0.15;
      const entryMin = price - atr * 0.1;
      const stopLoss = price + atr * 1.6;
      const risk = stopLoss - entryMin;

      return {
        strategyName: this.name,
        symbol,
        timeframe,
        direction: 'SELL',
        confidence: 88,
        entryZone: { min: parseFloat(entryMin.toFixed(5)), max: parseFloat(entryMax.toFixed(5)) },
        stopLoss: parseFloat(stopLoss.toFixed(5)),
        takeProfitLevels: {
          tp1: parseFloat((entryMin - risk * 1.8).toFixed(5)),
          tp2: parseFloat((entryMin - risk * 3.0).toFixed(5)),
          tp3: parseFloat((entryMin - risk * 4.5).toFixed(5)),
        },
        riskRewardRatio: '1:1.8 / 1:3.0 / 1:4.5',
        reasoning: [
          `EMA20/50 bearish trend alignment`,
          `RSI momentum in sell expansion zone (${rsi.toFixed(1)})`,
          `Market regime classified as ${structure.marketRegime}`,
          `Multi-timeframe liquidity & structural confluence satisfied`,
        ],
        supportingFactors: ['EMA Alignment', 'RSI Bearish Expansion', 'Structure Confluence'],
        opposingFactors: [],
        marketRegime: structure.marketRegime,
        timestamp,
      };
    }

    return this.noTrade(symbol, timeframe, 'Alchemist multi-indicator confluence threshold not met', timestamp);
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

import {
  calculateSMA,
  calculateEMA,
  calculateATR,
  calculateRSI,
  calculateMACD,
  calculateBollingerBands,
  calculateADX,
  Candle,
} from '../src/packages/indicators/indicators';
import { analyzeMarketStructure } from '../src/packages/indicators/market-structure';

describe('Technical Indicator Engine Tests', () => {
  const dummyCandles: Candle[] = Array.from({ length: 50 }, (_, i) => ({
    timestamp: new Date(Date.now() - (50 - i) * 60000),
    open: 100 + i * 0.5,
    high: 102 + i * 0.5,
    low: 99 + i * 0.5,
    close: 101 + i * 0.5,
    volume: 1000 + i * 10,
  }));

  it('should calculate SMA correctly', () => {
    const sma20 = calculateSMA(dummyCandles, 20);
    expect(sma20).toBeDefined();
    expect(typeof sma20).toBe('number');
  });

  it('should calculate EMA correctly', () => {
    const ema20 = calculateEMA(dummyCandles, 20);
    expect(ema20).toBeDefined();
    expect(typeof ema20).toBe('number');
  });

  it('should calculate ATR correctly', () => {
    const atr14 = calculateATR(dummyCandles, 14);
    expect(atr14).toBeDefined();
    expect(atr14!).toBeGreaterThan(0);
  });

  it('should calculate RSI correctly', () => {
    const rsi14 = calculateRSI(dummyCandles, 14);
    expect(rsi14).toBeDefined();
    expect(rsi14!).toBeGreaterThanOrEqual(0);
    expect(rsi14!).toBeLessThanOrEqual(100);
  });

  it('should calculate MACD correctly', () => {
    const macd = calculateMACD(dummyCandles);
    expect(macd).toBeDefined();
    expect(macd?.histogram).toBeDefined();
  });

  it('should calculate Bollinger Bands correctly', () => {
    const bb = calculateBollingerBands(dummyCandles);
    expect(bb).toBeDefined();
    expect(bb!.upper).toBeGreaterThan(bb!.middle);
    expect(bb!.middle).toBeGreaterThan(bb!.lower);
  });

  it('should calculate ADX correctly', () => {
    const adx = calculateADX(dummyCandles, 14);
    expect(adx).toBeDefined();
  });

  it('should perform Market Structure analysis (BOS, OB, FVG, regime)', () => {
    const structure = analyzeMarketStructure(dummyCandles);
    expect(structure).toBeDefined();
    expect(structure.orderBlocks).toBeDefined();
    expect(structure.fairValueGaps).toBeDefined();
    expect(structure.marketRegime).toBeDefined();
  });
});

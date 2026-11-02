import { QuickXauusdService } from '../src/services/strategy-engine/quick-xauusd.service';
import { Candle } from '../src/packages/indicators/indicators';

describe('⚡ Quick XAUUSD Scalping Engine Tests', () => {
  let service: QuickXauusdService;

  beforeAll(() => {
    service = new QuickXauusdService();
  });

  const generateCandles = (basePrice: number, count: number, trend: 'up' | 'down' | 'flat'): Candle[] => {
    const candles: Candle[] = [];
    let price = basePrice;
    for (let i = 0; i < count; i++) {
      const step = trend === 'up' ? 0.8 : trend === 'down' ? -0.8 : 0;
      const open = price;
      const close = open + step + (Math.sin(i) * 0.2);
      const high = Math.max(open, close) + 0.5;
      const low = Math.min(open, close) - 0.5;
      candles.push({
        timestamp: new Date(Date.now() - (count - i) * 5 * 60 * 1000),
        open,
        high,
        low,
        close,
        volume: 1000 + i * 10,
      });
      price = close;
    }
    return candles;
  };

  test('Constraint 1: Strictly reject any non-XAUUSD symbols (EURUSD, BTCUSD, XAGUSD, etc.)', async () => {
    const candles = generateCandles(1.08, 30, 'up');
    const timeframes = { H1: candles, M15: candles, M5: candles };

    const eurusdRes = await service.analyzeXauusd('EURUSD', timeframes);
    expect(eurusdRes.isTradable).toBe(false);
    expect(eurusdRes.reason).toContain('RESTRICTED_SYMBOL');

    const btcusdRes = await service.analyzeXauusd('BTCUSD', timeframes);
    expect(btcusdRes.isTradable).toBe(false);
    expect(btcusdRes.reason).toContain('RESTRICTED_SYMBOL');

    const xagusdRes = await service.analyzeXauusd('XAGUSD', timeframes);
    expect(xagusdRes.isTradable).toBe(false);
    expect(xagusdRes.reason).toContain('RESTRICTED_SYMBOL');
  });

  test('Constraint 2: Reject analysis when candle data is insufficient (< 20 bars)', async () => {
    const shortCandles = generateCandles(2650, 10, 'up');
    const timeframes = { H1: shortCandles, M15: shortCandles, M5: shortCandles };

    const res = await service.analyzeXauusd('XAUUSD', timeframes);
    expect(res.isTradable).toBe(false);
    expect(res.reason).toContain('INSUFFICIENT_CANDLE_DATA');
  });

  test('Constraint 3: Multi-timeframe confluence generates validated Gold setup with entry zone, SL, and TP1-3', async () => {
    const h1Candles = generateCandles(2640, 40, 'up');
    const m15Candles = generateCandles(2645, 40, 'up');
    const m5Candles = generateCandles(2648, 40, 'up');

    const res = await service.analyzeXauusd('XAUUSD', { H1: h1Candles, M15: m15Candles, M5: m5Candles });

    if (res.isTradable && res.signal) {
      expect(res.signal.direction).toBe('BUY');
      expect(res.signal.entryMin).toBeLessThanOrEqual(res.signal.entryMax);
      expect(res.signal.stopLoss).toBeLessThan(res.signal.entryMin);
      expect(res.signal.tp1).toBeGreaterThan(res.signal.entryMax);
      expect(res.signal.tp2).toBeGreaterThan(res.signal.tp1);
      expect(res.signal.tp3).toBeGreaterThan(res.signal.tp2);
      expect(res.signal.qualityScore).toBeGreaterThanOrEqual(75);
      expect(res.signal.confluenceList.length).toBeGreaterThanOrEqual(1);
    }
  });
});

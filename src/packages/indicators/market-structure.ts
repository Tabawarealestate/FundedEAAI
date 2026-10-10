import { Candle } from './indicators';

export interface SwingPoint {
  index: number;
  type: 'HIGH' | 'LOW';
  price: number;
  timestamp: Date;
}

export interface OrderBlock {
  type: 'BULLISH' | 'BEARISH';
  high: number;
  low: number;
  candleIndex: number;
  timestamp: Date;
  isFresh: boolean;
}

export interface FairValueGap {
  type: 'BULLISH' | 'BEARISH';
  top: number;
  bottom: number;
  candleIndex: number;
  timestamp: Date;
  isFilled: boolean;
}

export interface LiquiditySweep {
  type: 'BUY_SIDE' | 'SELL_SIDE';
  sweptPrice: number;
  reversalPrice: number;
  candleIndex: number;
  timestamp: Date;
}

export interface StructureAnalysis {
  swings: SwingPoint[];
  bos: { type: 'BULLISH' | 'BEARISH'; price: number; timestamp: Date } | null;
  choch: { type: 'BULLISH' | 'BEARISH'; price: number; timestamp: Date } | null;
  mss: { type: 'BULLISH' | 'BEARISH'; price: number; timestamp: Date } | null;
  orderBlocks: OrderBlock[];
  fairValueGaps: FairValueGap[];
  liquiditySweeps: LiquiditySweep[];
  premiumDiscountZone: 'PREMIUM' | 'DISCOUNT' | 'EQUILIBRIUM';
  marketRegime: 'STRONG_BULL' | 'WEAK_BULL' | 'STRONG_BEAR' | 'WEAK_BEAR' | 'RANGE' | 'HIGH_VOLATILITY' | 'UNCLEAR';
}

// 1. Detect Swing Highs and Lows (using fractal window n=2)
export function detectSwingPoints(candles: Candle[], window = 2): SwingPoint[] {
  const swings: SwingPoint[] = [];
  if (candles.length < window * 2 + 1) return swings;

  for (let i = window; i < candles.length - window; i++) {
    const currentHigh = candles[i].high;
    const currentLow = candles[i].low;

    let isSwingHigh = true;
    let isSwingLow = true;

    for (let j = i - window; j <= i + window; j++) {
      if (j === i) continue;
      if (candles[j].high >= currentHigh) isSwingHigh = false;
      if (candles[j].low <= currentLow) isSwingLow = false;
    }

    if (isSwingHigh) {
      swings.push({ index: i, type: 'HIGH', price: currentHigh, timestamp: candles[i].timestamp });
    }
    if (isSwingLow) {
      swings.push({ index: i, type: 'LOW', price: currentLow, timestamp: candles[i].timestamp });
    }
  }

  return swings;
}

// 2. Detect Fair Value Gaps (FVG)
export function detectFairValueGaps(candles: Candle[]): FairValueGap[] {
  const fvgs: FairValueGap[] = [];
  if (candles.length < 3) return fvgs;

  const currentPrice = candles[candles.length - 1].close;

  for (let i = 2; i < candles.length; i++) {
    const c1 = candles[i - 2];
    const c3 = candles[i];

    // Bullish FVG: Low of c3 > High of c1
    if (c3.low > c1.high) {
      const isFilled = currentPrice <= c1.high;
      fvgs.push({
        type: 'BULLISH',
        top: c3.low,
        bottom: c1.high,
        candleIndex: i - 1,
        timestamp: candles[i - 1].timestamp,
        isFilled,
      });
    }

    // Bearish FVG: High of c3 < Low of c1
    if (c3.high < c1.low) {
      const isFilled = currentPrice >= c1.low;
      fvgs.push({
        type: 'BEARISH',
        top: c1.low,
        bottom: c3.high,
        candleIndex: i - 1,
        timestamp: candles[i - 1].timestamp,
        isFilled,
      });
    }
  }

  return fvgs;
}

// 3. Detect Order Blocks (OB)
export function detectOrderBlocks(candles: Candle[], swings: SwingPoint[]): OrderBlock[] {
  const orderBlocks: OrderBlock[] = [];
  if (candles.length < 5) return orderBlocks;

  const currentPrice = candles[candles.length - 1].close;

  // Find displacement candles
  for (let i = 2; i < candles.length; i++) {
    const bodySize = Math.abs(candles[i].close - candles[i].open);
    const prevBody = Math.abs(candles[i - 1].close - candles[i - 1].open);

    // Strong displacement (displacement candle > 1.8x prev candle)
    if (bodySize > prevBody * 1.8) {
      if (candles[i].close > candles[i].open) {
        // Bullish displacement -> last bearish candle before impulse is Bullish Order Block
        const obCandle = candles[i - 1];
        if (obCandle.close < obCandle.open) {
          orderBlocks.push({
            type: 'BULLISH',
            high: obCandle.high,
            low: obCandle.low,
            candleIndex: i - 1,
            timestamp: obCandle.timestamp,
            isFresh: currentPrice >= obCandle.low,
          });
        }
      } else {
        // Bearish displacement -> last bullish candle before impulse is Bearish Order Block
        const obCandle = candles[i - 1];
        if (obCandle.close > obCandle.open) {
          orderBlocks.push({
            type: 'BEARISH',
            high: obCandle.high,
            low: obCandle.low,
            candleIndex: i - 1,
            timestamp: obCandle.timestamp,
            isFresh: currentPrice <= obCandle.high,
          });
        }
      }
    }
  }

  return orderBlocks;
}

// 4. Detect Liquidity Sweeps
export function detectLiquiditySweeps(candles: Candle[], swings: SwingPoint[]): LiquiditySweep[] {
  const sweeps: LiquiditySweep[] = [];
  if (swings.length === 0 || candles.length < 3) return sweeps;

  const recentCandles = candles.slice(-5);

  for (const swing of swings) {
    for (let i = 0; i < recentCandles.length; i++) {
      const c = recentCandles[i];
      // Sell-side sweep: Low pierces swing low but close is back above
      if (swing.type === 'LOW' && c.low < swing.price && c.close > swing.price) {
        sweeps.push({
          type: 'SELL_SIDE',
          sweptPrice: swing.price,
          reversalPrice: c.close,
          candleIndex: candles.length - 5 + i,
          timestamp: c.timestamp,
        });
      }

      // Buy-side sweep: High pierces swing high but close is back below
      if (swing.type === 'HIGH' && c.high > swing.price && c.close < swing.price) {
        sweeps.push({
          type: 'BUY_SIDE',
          sweptPrice: swing.price,
          reversalPrice: c.close,
          candleIndex: candles.length - 5 + i,
          timestamp: c.timestamp,
        });
      }
    }
  }

  return sweeps;
}

// 5. Full Market Structure Analysis
export function analyzeMarketStructure(candles: Candle[]): StructureAnalysis {
  const swings = detectSwingPoints(candles);
  const fvgs = detectFairValueGaps(candles);
  const obs = detectOrderBlocks(candles, swings);
  const sweeps = detectLiquiditySweeps(candles, swings);

  let bos: StructureAnalysis['bos'] = null;
  let choch: StructureAnalysis['choch'] = null;
  let mss: StructureAnalysis['mss'] = null;

  const recentCandle = candles[candles.length - 1];
  const recentHighs = swings.filter((s) => s.type === 'HIGH').slice(-3);
  const recentLows = swings.filter((s) => s.type === 'LOW').slice(-3);

  if (recentHighs.length >= 1 && recentCandle.close > recentHighs[recentHighs.length - 1].price) {
    bos = { type: 'BULLISH', price: recentHighs[recentHighs.length - 1].price, timestamp: recentCandle.timestamp };
    mss = { type: 'BULLISH', price: recentHighs[recentHighs.length - 1].price, timestamp: recentCandle.timestamp };
  } else if (recentLows.length >= 1 && recentCandle.close < recentLows[recentLows.length - 1].price) {
    bos = { type: 'BEARISH', price: recentLows[recentLows.length - 1].price, timestamp: recentCandle.timestamp };
    mss = { type: 'BEARISH', price: recentLows[recentLows.length - 1].price, timestamp: recentCandle.timestamp };
  }

  // Premium / Discount Zone
  let pdZone: StructureAnalysis['premiumDiscountZone'] = 'EQUILIBRIUM';
  if (swings.length >= 2) {
    const highest = Math.max(...candles.slice(-30).map((c) => c.high));
    const lowest = Math.min(...candles.slice(-30).map((c) => c.low));
    const eq = (highest + lowest) / 2;
    if (recentCandle.close > eq) pdZone = 'PREMIUM';
    else if (recentCandle.close < eq) pdZone = 'DISCOUNT';
  }

  // Market Regime Classification
  let regime: StructureAnalysis['marketRegime'] = 'UNCLEAR';
  if (recentHighs.length >= 2 && recentLows.length >= 2) {
    const isHigherHighs = recentHighs[1].price > recentHighs[0].price;
    const isHigherLows = recentLows[1].price > recentLows[0].price;
    const isLowerHighs = recentHighs[1].price < recentHighs[0].price;
    const isLowerLows = recentLows[1].price < recentLows[0].price;

    if (isHigherHighs && isHigherLows) regime = 'STRONG_BULL';
    else if (isLowerHighs && isLowerLows) regime = 'STRONG_BEAR';
    else if (isHigherHighs || isHigherLows) regime = 'WEAK_BULL';
    else if (isLowerHighs || isLowerLows) regime = 'WEAK_BEAR';
    else regime = 'RANGE';
  }

  return {
    swings,
    bos,
    choch,
    mss,
    orderBlocks: obs,
    fairValueGaps: fvgs,
    liquiditySweeps: sweeps,
    premiumDiscountZone: pdZone,
    marketRegime: regime,
  };
}

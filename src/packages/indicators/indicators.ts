export interface Candle {
  timestamp: Date;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

export interface IndicatorResults {
  sma20?: number;
  ema50?: number;
  ema200?: number;
  rsi14?: number;
  atr14?: number;
  macd?: { macd: number; signal: number; histogram: number };
  adx14?: number;
  bollinger?: { upper: number; middle: number; lower: number };
  vwap?: number;
}

// 1. Simple Moving Average (SMA)
export function calculateSMA(candles: Candle[], period: number): number | undefined {
  if (candles.length < period) return undefined;
  const slice = candles.slice(-period);
  const sum = slice.reduce((acc, c) => acc + c.close, 0);
  return sum / period;
}

// 2. Exponential Moving Average (EMA)
export function calculateEMA(candles: Candle[], period: number): number | undefined {
  if (candles.length < period) return undefined;
  const multiplier = 2 / (period + 1);
  let ema = calculateSMA(candles.slice(0, period), period)!;

  for (let i = period; i < candles.length; i++) {
    ema = (candles[i].close - ema) * multiplier + ema;
  }
  return ema;
}

// 3. Average True Range (ATR)
export function calculateATR(candles: Candle[], period = 14): number | undefined {
  if (candles.length <= period) return undefined;

  const trueRanges: number[] = [];
  for (let i = 1; i < candles.length; i++) {
    const high = candles[i].high;
    const low = candles[i].low;
    const prevClose = candles[i - 1].close;
    const tr = Math.max(high - low, Math.abs(high - prevClose), Math.abs(low - prevClose));
    trueRanges.push(tr);
  }

  if (trueRanges.length < period) return undefined;

  let atr = trueRanges.slice(0, period).reduce((a, b) => a + b, 0) / period;
  for (let i = period; i < trueRanges.length; i++) {
    atr = (atr * (period - 1) + trueRanges[i]) / period;
  }
  return atr;
}

// 4. Relative Strength Index (RSI)
export function calculateRSI(candles: Candle[], period = 14): number | undefined {
  if (candles.length <= period) return undefined;

  let gains = 0;
  let losses = 0;

  for (let i = 1; i <= period; i++) {
    const diff = candles[i].close - candles[i - 1].close;
    if (diff >= 0) gains += diff;
    else losses -= diff;
  }

  let avgGain = gains / period;
  let avgLoss = losses / period;

  for (let i = period + 1; i < candles.length; i++) {
    const diff = candles[i].close - candles[i - 1].close;
    if (diff >= 0) {
      avgGain = (avgGain * (period - 1) + diff) / period;
      avgLoss = (avgLoss * (period - 1)) / period;
    } else {
      avgGain = (avgGain * (period - 1)) / period;
      avgLoss = (avgLoss * (period - 1) - diff) / period;
    }
  }

  if (avgLoss === 0) return 100;
  const rs = avgGain / avgLoss;
  return 100 - 100 / (1 + rs);
}

// 5. MACD (12, 26, 9)
export function calculateMACD(candles: Candle[], fast = 12, slow = 26, signalPeriod = 9) {
  if (candles.length < slow + signalPeriod) return undefined;

  const macdValues: number[] = [];
  for (let i = slow; i <= candles.length; i++) {
    const subCandles = candles.slice(0, i);
    const fastEma = calculateEMA(subCandles, fast);
    const slowEma = calculateEMA(subCandles, slow);
    if (fastEma !== undefined && slowEma !== undefined) {
      macdValues.push(fastEma - slowEma);
    }
  }

  if (macdValues.length < signalPeriod) return undefined;

  // Calculate Signal line (EMA of MACD)
  const multiplier = 2 / (signalPeriod + 1);
  let signal = macdValues.slice(0, signalPeriod).reduce((a, b) => a + b, 0) / signalPeriod;

  for (let i = signalPeriod; i < macdValues.length; i++) {
    signal = (macdValues[i] - signal) * multiplier + signal;
  }

  const latestMacd = macdValues[macdValues.length - 1];
  return {
    macd: latestMacd,
    signal: signal,
    histogram: latestMacd - signal,
  };
}

// 6. Bollinger Bands
export function calculateBollingerBands(candles: Candle[], period = 20, multiplier = 2.0) {
  if (candles.length < period) return undefined;
  const sma = calculateSMA(candles, period)!;
  const slice = candles.slice(-period);
  const variance = slice.reduce((acc, c) => acc + Math.pow(c.close - sma, 2), 0) / period;
  const stdDev = Math.sqrt(variance);

  return {
    upper: sma + multiplier * stdDev,
    middle: sma,
    lower: sma - multiplier * stdDev,
  };
}

// 7. VWAP
export function calculateVWAP(candles: Candle[]): number | undefined {
  if (candles.length === 0) return undefined;
  let cumVolumePrice = 0;
  let cumVolume = 0;

  for (const c of candles) {
    const typicalPrice = (c.high + c.low + c.close) / 3;
    cumVolumePrice += typicalPrice * c.volume;
    cumVolume += c.volume;
  }

  return cumVolume > 0 ? cumVolumePrice / cumVolume : undefined;
}

// 8. ADX (Average Directional Index)
export function calculateADX(candles: Candle[], period = 14): number | undefined {
  if (candles.length <= period * 2) return undefined;

  const trs: number[] = [];
  const plusDMs: number[] = [];
  const minusDMs: number[] = [];

  for (let i = 1; i < candles.length; i++) {
    const cur = candles[i];
    const prev = candles[i - 1];

    const tr = Math.max(cur.high - cur.low, Math.abs(cur.high - prev.close), Math.abs(cur.low - prev.close));
    const upMove = cur.high - prev.high;
    const downMove = prev.low - cur.low;

    const plusDM = upMove > downMove && upMove > 0 ? upMove : 0;
    const minusDM = downMove > upMove && downMove > 0 ? downMove : 0;

    trs.push(tr);
    plusDMs.push(plusDM);
    minusDMs.push(minusDM);
  }

  if (trs.length < period) return undefined;

  let smoothedTR = trs.slice(0, period).reduce((a, b) => a + b, 0);
  let smoothedPlusDM = plusDMs.slice(0, period).reduce((a, b) => a + b, 0);
  let smoothedMinusDM = minusDMs.slice(0, period).reduce((a, b) => a + b, 0);

  const dxList: number[] = [];

  for (let i = period; i < trs.length; i++) {
    smoothedTR = smoothedTR - smoothedTR / period + trs[i];
    smoothedPlusDM = smoothedPlusDM - smoothedPlusDM / period + plusDMs[i];
    smoothedMinusDM = smoothedMinusDM - smoothedMinusDM / period + minusDMs[i];

    const plusDI = (smoothedPlusDM / smoothedTR) * 100;
    const minusDI = (smoothedMinusDM / smoothedTR) * 100;

    const diDiff = Math.abs(plusDI - minusDI);
    const diSum = plusDI + minusDI;
    const dx = diSum === 0 ? 0 : (diDiff / diSum) * 100;
    dxList.push(dx);
  }

  if (dxList.length < period) return undefined;

  let adx = dxList.slice(0, period).reduce((a, b) => a + b, 0) / period;
  for (let i = period; i < dxList.length; i++) {
    adx = (adx * (period - 1) + dxList[i]) / period;
  }

  return adx;
}

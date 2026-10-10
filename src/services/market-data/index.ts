import { MarketDataProvider, Quote } from './provider.interface';
import { TwelveDataProvider } from './twelve-data.provider';
import { CryptoProvider } from './crypto.provider';
import { ForexProvider } from './forex.provider';
import { Candle } from '../../packages/indicators/indicators';

export class CompositeMarketDataProvider implements MarketDataProvider {
  name = 'CompositeMarketDataProvider';
  private providers: MarketDataProvider[];
  private candleCache: Map<string, { candles: Candle[]; cachedAt: number }> = new Map();
  private cacheTtlMs = 10000; // 10 seconds cache

  constructor() {
    this.providers = [
      new TwelveDataProvider(),
      new CryptoProvider(),
      new ForexProvider(),
    ];
  }

  async isAvailable(): Promise<boolean> {
    for (const p of this.providers) {
      if (await p.isAvailable()) return true;
    }
    return false;
  }

  async fetchCandles(symbol: string, timeframe: string, limit = 100): Promise<Candle[]> {
    const cacheKey = `${symbol}:${timeframe}:${limit}`;
    const cached = this.candleCache.get(cacheKey);
    if (cached && Date.now() - cached.cachedAt < this.cacheTtlMs) {
      return cached.candles;
    }

    // Try providers sequentially with retry and backoff
    for (const provider of this.getPrioritizedProviders(symbol)) {
      const candles = await this.retryWithBackoff(() => provider.fetchCandles(symbol, timeframe, limit), 2, 300);
      if (candles && candles.length > 0) {
        this.candleCache.set(cacheKey, { candles, cachedAt: Date.now() });
        return candles;
      }
    }

    // If no provider returns data, output empty array (calling code displays "DATA UNAVAILABLE")
    return [];
  }

  async fetchQuote(symbol: string): Promise<Quote | null> {
    for (const provider of this.getPrioritizedProviders(symbol)) {
      const quote = await this.retryWithBackoff(() => provider.fetchQuote(symbol), 2, 200);
      if (quote) return quote;
    }
    return null;
  }

  private getPrioritizedProviders(symbol: string): MarketDataProvider[] {
    if (symbol.startsWith('BTC') || symbol.startsWith('ETH') || symbol.endsWith('USDT')) {
      return [this.providers[1], this.providers[0], this.providers[2]];
    }
    return [this.providers[0], this.providers[2], this.providers[1]];
  }

  private async retryWithBackoff<T>(fn: () => Promise<T>, retries: number, delayMs: number): Promise<T | null> {
    let attempt = 0;
    while (attempt <= retries) {
      try {
        const res = await fn();
        if (res) return res;
      } catch (err) {
        // Continue to retry
      }
      attempt++;
      if (attempt <= retries) {
        await new Promise((resolve) => setTimeout(resolve, delayMs * Math.pow(2, attempt - 1)));
      }
    }
    return null;
  }
}

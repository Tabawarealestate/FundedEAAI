import axios from 'axios';
import { MarketDataProvider, Quote } from './provider.interface';
import { Candle } from '../../packages/indicators/indicators';

export class CryptoProvider implements MarketDataProvider {
  name = 'CryptoProvider';
  private baseUrl = 'https://api.binance.com/api/v3';

  async isAvailable(): Promise<boolean> {
    try {
      const res = await axios.get(`${this.baseUrl}/ping`, { timeout: 3000 });
      return res.status === 200;
    } catch {
      return false;
    }
  }

  async fetchCandles(symbol: string, timeframe: string, limit = 100): Promise<Candle[]> {
    try {
      const pair = this.formatSymbol(symbol);
      const interval = this.mapTimeframe(timeframe);
      const res = await axios.get(`${this.baseUrl}/klines`, {
        params: {
          symbol: pair,
          interval,
          limit,
        },
        timeout: 5000,
      });

      if (!Array.isArray(res.data)) return [];

      return res.data.map((k: any) => ({
        timestamp: new Date(k[0]),
        open: parseFloat(k[1]),
        high: parseFloat(k[2]),
        low: parseFloat(k[3]),
        close: parseFloat(k[4]),
        volume: parseFloat(k[5]),
      }));
    } catch {
      return [];
    }
  }

  async fetchQuote(symbol: string): Promise<Quote | null> {
    try {
      const pair = this.formatSymbol(symbol);
      const res = await axios.get(`${this.baseUrl}/ticker/bookTicker`, {
        params: { symbol: pair },
        timeout: 3000,
      });

      if (!res.data || !res.data.bidPrice) return null;

      const bid = parseFloat(res.data.bidPrice);
      const ask = parseFloat(res.data.askPrice);

      return {
        symbol,
        bid,
        ask,
        spread: Math.abs(ask - bid),
        timestamp: new Date(),
        provider: this.name,
      };
    } catch {
      return null;
    }
  }

  private formatSymbol(symbol: string): string {
    if (symbol === 'BTCUSD') return 'BTCUSDT';
    if (symbol === 'ETHUSD') return 'ETHUSDT';
    return symbol.replace('USD', 'USDT');
  }

  private mapTimeframe(tf: string): string {
    const map: Record<string, string> = {
      M1: '1m',
      M5: '5m',
      M15: '15m',
      M30: '30m',
      H1: '1h',
      H4: '4h',
      D1: '1d',
    };
    return map[tf] || '15m';
  }
}

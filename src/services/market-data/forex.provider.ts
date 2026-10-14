import axios from 'axios';
import { MarketDataProvider, Quote } from './provider.interface';
import { Candle } from '../../packages/indicators/indicators';

export class ForexProvider implements MarketDataProvider {
  name = 'ForexProvider';

  async isAvailable(): Promise<boolean> {
    try {
      const res = await axios.get('https://api.frankfurter.app/latest', { timeout: 3000 });
      return res.status === 200;
    } catch {
      return false;
    }
  }

  async fetchCandles(symbol: string, timeframe: string, limit = 100): Promise<Candle[]> {
    // Return [] if provider endpoint does not supply real historical candle series
    // Calling system outputs DATA UNAVAILABLE as strictly required
    return [];
  }

  async fetchQuote(symbol: string): Promise<Quote | null> {
    try {
      const base = symbol.substring(0, 3);
      const quoteCurrency = symbol.substring(3, 6);
      const res = await axios.get(`https://api.frankfurter.app/latest`, {
        params: { from: base, to: quoteCurrency },
        timeout: 3000,
      });

      if (!res.data || !res.data.rates || !res.data.rates[quoteCurrency]) return null;

      const rate = parseFloat(res.data.rates[quoteCurrency]);
      const spread = rate * 0.0001;

      return {
        symbol,
        bid: rate,
        ask: rate + spread,
        spread,
        timestamp: new Date(),
        provider: this.name,
      };
    } catch {
      return null;
    }
  }
}

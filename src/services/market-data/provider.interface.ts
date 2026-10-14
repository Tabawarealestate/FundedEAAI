import { Candle } from '../../packages/indicators/indicators';

export interface Quote {
  symbol: string;
  bid: number;
  ask: number;
  spread: number;
  timestamp: Date;
  provider: string;
}

export interface MarketDataProvider {
  name: string;
  isAvailable(): Promise<boolean>;
  fetchCandles(symbol: string, timeframe: string, limit?: number): Promise<Candle[]>;
  fetchQuote(symbol: string): Promise<Quote | null>;
}

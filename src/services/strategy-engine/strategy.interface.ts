import { Candle } from '../../packages/indicators/indicators';

export interface StrategyResult {
  strategyName: string;
  symbol: string;
  timeframe: string;
  direction: 'BUY' | 'SELL' | 'NO_TRADE';
  confidence: number; // 0 - 100
  entryZone: { min: number; max: number };
  stopLoss: number;
  takeProfitLevels: { tp1: number; tp2: number; tp3: number };
  riskRewardRatio: string;
  reasoning: string[];
  supportingFactors: string[];
  opposingFactors: string[];
  marketRegime: string;
  timestamp: Date;
}

export interface StrategyEngine {
  name: string;
  requiresPremium: boolean;
  analyze(symbol: string, timeframe: string, candles: Candle[]): Promise<StrategyResult>;
}

import { Candle } from '../../packages/indicators/indicators';
import { StrategyEngine } from '../strategy-engine/strategy.interface';

export interface BacktestConfig {
  symbol: string;
  timeframe: string;
  initialBalance: number;
  riskPerTradePercent: number; // e.g. 1.0%
  spreadPips: number;
  slippagePips: number;
}

export interface TradeRecord {
  id: number;
  direction: 'BUY' | 'SELL';
  entryPrice: number;
  stopLoss: number;
  tp1: number;
  tp2: number;
  tp3: number;
  exitPrice: number;
  exitReason: 'TP1' | 'TP2' | 'TP3' | 'SL' | 'EXPIRED';
  profitUsd: number;
  returnR: number;
  timestamp: Date;
}

export interface BacktestReport {
  symbol: string;
  timeframe: string;
  strategyName: string;
  totalCandlesEvaluated: number;
  totalTrades: number;
  wins: number;
  losses: number;
  winRatePercent: number;
  averageR: number;
  profitFactor: number;
  maxDrawdownPercent: number;
  netProfitUsd: number;
  finalBalance: number;
  trades: TradeRecord[];
}

export class BacktestEngine {
  async runBacktest(
    strategy: StrategyEngine,
    candles: Candle[],
    config: BacktestConfig
  ): Promise<BacktestReport> {
    let balance = config.initialBalance;
    let peakBalance = balance;
    let maxDrawdownUsd = 0;

    const trades: TradeRecord[] = [];
    let wins = 0;
    let losses = 0;
    let grossProfit = 0;
    let grossLoss = 0;
    let sumR = 0;

    const minCandleWindow = 50;

    for (let i = minCandleWindow; i < candles.length - 1; i++) {
      const windowCandles = candles.slice(0, i + 1);
      const setup = await strategy.analyze(config.symbol, config.timeframe, windowCandles);

      if (setup.direction === 'NO_TRADE' || setup.confidence < 75) continue;

      const entryPrice = (setup.entryZone.min + setup.entryZone.max) / 2;
      const stopLoss = setup.stopLoss;
      const riskAmountUsd = balance * (config.riskPerTradePercent / 100);
      const riskPerShare = Math.abs(entryPrice - stopLoss);

      if (riskPerShare === 0) continue;

      const positionUnits = riskAmountUsd / riskPerShare;
      const futureCandles = candles.slice(i + 1, i + 30); // Simulate next 30 candles

      let tradeExitReason: TradeRecord['exitReason'] | null = null;
      let exitPrice = entryPrice;

      for (const fc of futureCandles) {
        if (setup.direction === 'BUY') {
          if (fc.low <= stopLoss) {
            tradeExitReason = 'SL';
            exitPrice = stopLoss;
            break;
          }
          if (fc.high >= setup.takeProfitLevels.tp3) {
            tradeExitReason = 'TP3';
            exitPrice = setup.takeProfitLevels.tp3;
            break;
          }
          if (fc.high >= setup.takeProfitLevels.tp1) {
            tradeExitReason = 'TP1';
            exitPrice = setup.takeProfitLevels.tp1;
            break;
          }
        } else {
          if (fc.high >= stopLoss) {
            tradeExitReason = 'SL';
            exitPrice = stopLoss;
            break;
          }
          if (fc.low <= setup.takeProfitLevels.tp3) {
            tradeExitReason = 'TP3';
            exitPrice = setup.takeProfitLevels.tp3;
            break;
          }
          if (fc.low <= setup.takeProfitLevels.tp1) {
            tradeExitReason = 'TP1';
            exitPrice = setup.takeProfitLevels.tp1;
            break;
          }
        }
      }

      if (!tradeExitReason) {
        tradeExitReason = 'EXPIRED';
        exitPrice = futureCandles[futureCandles.length - 1]?.close || entryPrice;
      }

      const rawPnl =
        setup.direction === 'BUY'
          ? (exitPrice - entryPrice) * positionUnits
          : (entryPrice - exitPrice) * positionUnits;

      const returnR = rawPnl / riskAmountUsd;

      balance += rawPnl;
      if (balance > peakBalance) peakBalance = balance;
      const dd = peakBalance - balance;
      if (dd > maxDrawdownUsd) maxDrawdownUsd = dd;

      if (rawPnl > 0) {
        wins++;
        grossProfit += rawPnl;
      } else {
        losses++;
        grossLoss += Math.abs(rawPnl);
      }

      sumR += returnR;

      trades.push({
        id: trades.length + 1,
        direction: setup.direction,
        entryPrice,
        stopLoss,
        tp1: setup.takeProfitLevels.tp1,
        tp2: setup.takeProfitLevels.tp2,
        tp3: setup.takeProfitLevels.tp3,
        exitPrice,
        exitReason: tradeExitReason,
        profitUsd: parseFloat(rawPnl.toFixed(2)),
        returnR: parseFloat(returnR.toFixed(2)),
        timestamp: candles[i].timestamp,
      });

      // Jump forward to avoid overlapping duplicate signals on consecutive candles
      i += 5;
    }

    const totalTrades = trades.length;
    const winRatePercent = totalTrades > 0 ? (wins / totalTrades) * 100 : 0;
    const averageR = totalTrades > 0 ? sumR / totalTrades : 0;
    const profitFactor = grossLoss > 0 ? grossProfit / grossLoss : grossProfit > 0 ? 99 : 0;
    const maxDrawdownPercent = peakBalance > 0 ? (maxDrawdownUsd / peakBalance) * 100 : 0;

    return {
      symbol: config.symbol,
      timeframe: config.timeframe,
      strategyName: strategy.name,
      totalCandlesEvaluated: candles.length,
      totalTrades,
      wins,
      losses,
      winRatePercent: parseFloat(winRatePercent.toFixed(2)),
      averageR: parseFloat(averageR.toFixed(2)),
      profitFactor: parseFloat(profitFactor.toFixed(2)),
      maxDrawdownPercent: parseFloat(maxDrawdownPercent.toFixed(2)),
      netProfitUsd: parseFloat((balance - config.initialBalance).toFixed(2)),
      finalBalance: parseFloat(balance.toFixed(2)),
      trades,
    };
  }
}

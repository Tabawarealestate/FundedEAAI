import { Candle } from '../../packages/indicators/indicators';
import { StrategyResult } from './strategy.interface';
import { SMCStrategy } from './smc.strategy';
import { AlchemistStrategy } from './alchemist.strategy';
import { TrendFollowingStrategy } from './trend.strategy';
import { BreakoutStrategy } from './breakout.strategy';
import { QuickScalpingStrategy } from './quick-scalping.strategy';
import { EnsembleEngine } from './ensemble.engine';

export interface QuickXauusdAnalysisResult {
  symbol: string;
  isTradable: boolean;
  reason?: string;
  signal?: {
    direction: 'BUY' | 'SELL';
    entryMin: number;
    entryMax: number;
    stopLoss: number;
    tp1: number;
    tp2: number;
    tp3: number;
    riskReward: string;
    qualityScore: number;
    timeframe: string;
    session: string;
    confluenceList: string[];
    reasoning: string[];
    supportingFactors: string[];
    opposingFactors: string[];
    invalidationReason: string;
    consensusSummary: string;
  };
}

export class QuickXauusdService {
  private smcStrategy = new SMCStrategy();
  private alchemistStrategy = new AlchemistStrategy();
  private trendStrategy = new TrendFollowingStrategy();
  private breakoutStrategy = new BreakoutStrategy();
  private quickScalpingStrategy = new QuickScalpingStrategy();
  private ensembleEngine = new EnsembleEngine();

  /**
   * Strictly evaluates ONLY XAUUSD / GOLD candles.
   * Hard constraint: Any symbol other than XAUUSD is immediately rejected.
   */
  public async analyzeXauusd(
    symbol: string,
    timeframes: {
      H4?: Candle[];
      H1: Candle[];
      M15: Candle[];
      M5: Candle[];
      M1?: Candle[];
    },
    session: string = 'London'
  ): Promise<QuickXauusdAnalysisResult> {
    const cleanSym = symbol.replace('/', '').toUpperCase();

    // 1. Hard restriction: XAUUSD ONLY
    if (cleanSym !== 'XAUUSD' && cleanSym !== 'GOLD') {
      return {
        symbol,
        isTradable: false,
        reason: 'RESTRICTED_SYMBOL: Quick Scalping engine is strictly restricted to XAUUSD / GOLD only.',
      };
    }

    // 2. Data Freshness and Sufficiency Checks
    if (!timeframes.M5 || timeframes.M5.length < 20 || !timeframes.M15 || timeframes.M15.length < 20 || !timeframes.H1 || timeframes.H1.length < 20) {
      return {
        symbol: 'XAUUSD',
        isTradable: false,
        reason: 'INSUFFICIENT_CANDLE_DATA: Multi-timeframe analysis requires at least 20 bars on H1, M15, and M5.',
      };
    }

    const currentM5 = timeframes.M5[timeframes.M5.length - 1];
    const currentPrice = currentM5.close;

    // 3. Multi-Strategy Analysis using Real Strategy Engines
    const smcRes = await this.smcStrategy.analyze('XAUUSD', 'M15', timeframes.M15);
    const alchemistRes = await this.alchemistStrategy.analyze('XAUUSD', 'M15', timeframes.M15);
    const trendRes = await this.trendStrategy.analyze('XAUUSD', 'H1', timeframes.H1);
    const breakoutRes = await this.breakoutStrategy.analyze('XAUUSD', 'M15', timeframes.M15);
    const scalpingRes = await this.quickScalpingStrategy.analyze('XAUUSD', 'M5', timeframes.M5);

    const activeStrategies: StrategyResult[] = [
      smcRes,
      alchemistRes,
      trendRes,
      breakoutRes,
      scalpingRes,
    ];

    // 4. AI Consensus Evaluation (Weighted Conflict Resolution)
    const ensembleDecision = await this.ensembleEngine.evaluateConsensus('XAUUSD', 'M5', timeframes.M5);

    if (ensembleDecision.finalDirection === 'NO_TRADE') {
      return {
        symbol: 'XAUUSD',
        isTradable: false,
        reason: `AI_CONSENSUS_NO_TRADE: Conflicted or low-conviction signals across strategies. Buy Votes: ${ensembleDecision.buyVotes}, Sell Votes: ${ensembleDecision.sellVotes}.`,
      };
    }

    const direction = ensembleDecision.finalDirection; // 'BUY' | 'SELL'
    const agreeingStrategies = activeStrategies.filter((s) => s.direction === direction);

    // Require at least 2 concurring strategies for high-quality Gold scalping
    if (agreeingStrategies.length < 2) {
      return {
        symbol: 'XAUUSD',
        isTradable: false,
        reason: `INSUFFICIENT_STRATEGY_CONFLUENCE: Only ${agreeingStrategies.length} strategies aligned with ${direction}. Minimum 2 required.`,
      };
    }

    // 5. Structure-Based Entry Zone, Stop Loss & Take Profits (Gold Market Precision: 2 decimals)
    const m5Atr = this.calculateAtr(timeframes.M5, 14);
    const buffer = Math.max(1.5, m5Atr * 1.2); // minimum $1.50 Gold structural buffer

    let entryMin: number;
    let entryMax: number;
    let stopLoss: number;
    let tp1: number;
    let tp2: number;
    let tp3: number;
    let invalidationReason: string;

    if (direction === 'BUY') {
      const recentM5Low = Math.min(...timeframes.M5.slice(-10).map((c) => c.low));
      const entryMid = currentPrice;
      entryMin = Number((entryMid - buffer * 0.4).toFixed(2));
      entryMax = Number((entryMid + buffer * 0.2).toFixed(2));
      stopLoss = Number((Math.min(recentM5Low - buffer * 0.5, entryMin - buffer * 1.5)).toFixed(2));

      const risk = entryMax - stopLoss;
      tp1 = Number((entryMax + risk * 1.5).toFixed(2));
      tp2 = Number((entryMax + risk * 2.5).toFixed(2));
      tp3 = Number((entryMax + risk * 4.0).toFixed(2));
      invalidationReason = `M15/M5 structural break below support/liquidity sweep level ${stopLoss}`;
    } else {
      const recentM5High = Math.max(...timeframes.M5.slice(-10).map((c) => c.high));
      const entryMid = currentPrice;
      entryMin = Number((entryMid - buffer * 0.2).toFixed(2));
      entryMax = Number((entryMid + buffer * 0.4).toFixed(2));
      stopLoss = Number((Math.max(recentM5High + buffer * 0.5, entryMax + buffer * 1.5)).toFixed(2));

      const risk = stopLoss - entryMin;
      tp1 = Number((entryMin - risk * 1.5).toFixed(2));
      tp2 = Number((entryMin - risk * 2.5).toFixed(2));
      tp3 = Number((entryMin - risk * 4.0).toFixed(2));
      invalidationReason = `M15/M5 structural break above resistance/liquidity sweep level ${stopLoss}`;
    }

    const calculatedRr = '1:1.5 / 1:2.5 / 1:4.0';

    // 6. Confluence & Reasoning Aggregation
    const confluenceList = agreeingStrategies.map((s) => s.strategyName);
    const allReasons = agreeingStrategies.flatMap((s) => s.reasoning).slice(0, 5);
    const supportingFactors = agreeingStrategies.flatMap((s) => s.supportingFactors).slice(0, 4);
    const opposingFactors = activeStrategies.filter((s) => s.direction !== direction && s.direction !== 'NO_TRADE').flatMap((s) => s.opposingFactors);

    // Compute Confluence Quality Score (75 - 98)
    const baseScore = ensembleDecision.consensusScore || 80;
    const strategyBonus = agreeingStrategies.length * 3;
    const qualityScore = Math.min(98, Math.max(75, baseScore + strategyBonus));

    const consensusSummary = `AI Consensus Confluence: ${agreeingStrategies.length}/5 strategies aligned ${direction} (Score: ${qualityScore}/100, Buy Votes: ${ensembleDecision.buyVotes}, Sell Votes: ${ensembleDecision.sellVotes})`;

    return {
      symbol: 'XAUUSD',
      isTradable: true,
      signal: {
        direction,
        entryMin,
        entryMax,
        stopLoss,
        tp1,
        tp2,
        tp3,
        riskReward: calculatedRr,
        qualityScore,
        timeframe: 'M5',
        session,
        confluenceList,
        reasoning: allReasons.length > 0 ? allReasons : [`${direction} momentum and liquidity displacement on M5`],
        supportingFactors: supportingFactors.length > 0 ? supportingFactors : ['Confluent multi-timeframe structure'],
        opposingFactors,
        invalidationReason,
        consensusSummary,
      },
    };
  }

  private calculateAtr(candles: Candle[], period = 14): number {
    if (candles.length < 2) return 1.5;
    let trSum = 0;
    const slice = candles.slice(-period - 1);
    for (let i = 1; i < slice.length; i++) {
      const high = slice[i].high;
      const low = slice[i].low;
      const prevClose = slice[i - 1].close;
      const tr = Math.max(high - low, Math.abs(high - prevClose), Math.abs(low - prevClose));
      trSum += tr;
    }
    return Number((trSum / (slice.length - 1)).toFixed(2));
  }
}

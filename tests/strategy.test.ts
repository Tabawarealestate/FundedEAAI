import { SMCStrategy } from '../src/services/strategy-engine/smc.strategy';
import { AlchemistStrategy } from '../src/services/strategy-engine/alchemist.strategy';
import { EnsembleEngine } from '../src/services/strategy-engine/ensemble.engine';
import { RiskEngine } from '../src/services/signal-engine/risk.engine';
import { Candle } from '../src/packages/indicators/indicators';

describe('Multi-Strategy Engine & Consensus Tests', () => {
  const sampleCandles: Candle[] = Array.from({ length: 60 }, (_, i) => ({
    timestamp: new Date(Date.now() - (60 - i) * 60000),
    open: 2600 + i * 0.8,
    high: 2602 + i * 0.8,
    low: 2599 + i * 0.8,
    close: 2601.5 + i * 0.8,
    volume: 500,
  }));

  it('should evaluate SMC strategy structured result', async () => {
    const smc = new SMCStrategy();
    const result = await smc.analyze('XAUUSD', 'M15', sampleCandles);
    expect(result).toBeDefined();
    expect(result.strategyName).toBe('Smart Money Concepts');
    expect(['BUY', 'SELL', 'NO_TRADE']).toContain(result.direction);
  });

  it('should evaluate Alchemist strategy structured result', async () => {
    const alchemist = new AlchemistStrategy();
    const result = await alchemist.analyze('XAUUSD', 'M15', sampleCandles);
    expect(result).toBeDefined();
    expect(result.strategyName).toBe('Alchemist');
  });

  it('should evaluate Ensemble AI Consensus Engine', async () => {
    const ensemble = new EnsembleEngine();
    const consensus = await ensemble.evaluateConsensus('XAUUSD', 'M15', sampleCandles);
    expect(consensus).toBeDefined();
    expect(['BUY', 'SELL', 'NO_TRADE']).toContain(consensus.finalDirection);
  });

  it('should reject signals with Risk Engine if score is low or quota exceeded', () => {
    const riskEngine = new RiskEngine();

    const lowScoreRes = riskEngine.evaluateRisk({
      symbol: 'XAUUSD',
      direction: 'BUY',
      qualityScore: 60, // Below 75
      spread: 0.2,
      pipSize: 0.1,
      dailySignalsSent: 1,
      maxDailyQuota: 5,
    });
    expect(lowScoreRes.isApproved).toBe(false);

    const quotaExceededRes = riskEngine.evaluateRisk({
      symbol: 'XAUUSD',
      direction: 'BUY',
      qualityScore: 88,
      spread: 0.2,
      pipSize: 0.1,
      dailySignalsSent: 5, // Quota reached
      maxDailyQuota: 5,
    });
    expect(quotaExceededRes.isApproved).toBe(false);

    const approvedRes = riskEngine.evaluateRisk({
      symbol: 'XAUUSD',
      direction: 'BUY',
      qualityScore: 88,
      spread: 0.2,
      pipSize: 0.1,
      dailySignalsSent: 2,
      maxDailyQuota: 5,
    });
    expect(approvedRes.isApproved).toBe(true);
  });
});

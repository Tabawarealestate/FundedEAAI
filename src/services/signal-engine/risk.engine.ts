export interface RiskCheckResult {
  isApproved: boolean;
  rejectionReason?: string;
  riskScore: number;
}

export interface RiskCheckInput {
  symbol: string;
  direction: 'BUY' | 'SELL';
  qualityScore: number;
  spread: number;
  pipSize: number;
  dailySignalsSent: number;
  maxDailyQuota: number;
  isHighImpactNewsImminent?: boolean;
}

export class RiskEngine {
  private minQualityThreshold = 75;
  private maxSpreadPips = 5.0;

  evaluateRisk(input: RiskCheckInput): RiskCheckResult {
    // 1. Daily Quota Check
    if (input.dailySignalsSent >= input.maxDailyQuota) {
      return {
        isApproved: false,
        rejectionReason: `Daily signal quota reached (${input.dailySignalsSent}/${input.maxDailyQuota}). No further trade generation today.`,
        riskScore: 0,
      };
    }

    // 2. Minimum Signal Quality Score
    if (input.qualityScore < this.minQualityThreshold) {
      return {
        isApproved: false,
        rejectionReason: `Signal quality score (${input.qualityScore}/100) below minimum required threshold (${this.minQualityThreshold}/100).`,
        riskScore: input.qualityScore,
      };
    }

    // 3. Spread Filter Check
    const spreadInPips = input.spread / input.pipSize;
    if (spreadInPips > this.maxSpreadPips) {
      return {
        isApproved: false,
        rejectionReason: `Excessive spread detected: ${spreadInPips.toFixed(1)} pips exceeds maximum allowed limit (${this.maxSpreadPips} pips).`,
        riskScore: 0,
      };
    }

    // 4. High Impact News Event Filter
    if (input.isHighImpactNewsImminent) {
      return {
        isApproved: false,
        rejectionReason: `High-impact economic news event imminent within 15 minutes. Trade rejected by Risk Engine.`,
        riskScore: 0,
      };
    }

    return {
      isApproved: true,
      riskScore: input.qualityScore,
    };
  }
}

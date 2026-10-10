import crypto from 'crypto';

export interface FingerprintParams {
  symbol: string;
  strategyCode: string;
  direction: string;
  timeframe: string;
  entryMin: number;
  entryMax: number;
  timeWindowHours?: number;
}

export class SignalDeduplicationService {
  private activeFingerprints: Map<string, number> = new Map();
  private defaultCooldownMs = 3600 * 1000; // 1 hour cooldown

  generateFingerprint(params: FingerprintParams): string {
    const timeWindowHours = params.timeWindowHours || 1;
    const now = new Date();
    const windowBucket = Math.floor(now.getTime() / (timeWindowHours * 3600 * 1000));

    const rawKey = `${params.symbol.toUpperCase()}:${params.strategyCode.toUpperCase()}:${params.direction.toUpperCase()}:${params.timeframe}:${params.entryMin.toFixed(2)}:${params.entryMax.toFixed(2)}:${windowBucket}`;
    return crypto.createHash('sha256').update(rawKey).digest('hex');
  }

  isDuplicate(fingerprint: string): boolean {
    const lastSeen = this.activeFingerprints.get(fingerprint);
    if (!lastSeen) return false;

    if (Date.now() - lastSeen < this.defaultCooldownMs) {
      return true;
    }
    return false;
  }

  recordSignal(fingerprint: string): void {
    this.activeFingerprints.set(fingerprint, Date.now());
  }
}

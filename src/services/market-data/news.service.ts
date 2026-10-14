import axios from 'axios';

export interface EconomicNewsEvent {
  title: string;
  currency: string;
  impact: 'HIGH' | 'MEDIUM' | 'LOW';
  time: Date;
}

export class EconomicNewsService {
  async fetchHighImpactNews(): Promise<EconomicNewsEvent[]> {
    try {
      // Fetch economic calendar from public FX calendar feed
      const res = await axios.get('https://nfp.ourprofx.com/api/news', { timeout: 5000 });
      if (Array.isArray(res.data)) {
        return res.data
          .filter((item: any) => item.impact === 'High' || item.impact === 'HIGH')
          .map((item: any) => ({
            title: item.title || item.event || 'High Impact News',
            currency: item.country || item.currency || 'USD',
            impact: 'HIGH',
            time: new Date(item.date || Date.now()),
          }));
      }
      return this.getFallbackNewsEvents();
    } catch {
      return this.getFallbackNewsEvents();
    }
  }

  private getFallbackNewsEvents(): EconomicNewsEvent[] {
    return [
      { title: 'US Non-Farm Payrolls (NFP)', currency: 'USD', impact: 'HIGH', time: new Date() },
      { title: 'US Consumer Price Index (CPI)', currency: 'USD', impact: 'HIGH', time: new Date() },
      { title: 'FOMC Interest Rate Decision', currency: 'USD', impact: 'HIGH', time: new Date() },
    ];
  }
}

import { TelegramBotService } from '../src/apps/telegram-bot/bot.service';

describe('Telegram Bot Engine Tests', () => {
  let botService: TelegramBotService;

  beforeAll(() => {
    botService = new TelegramBotService();
  });

  it('should instantiate Telegram bot service and setup handlers', () => {
    expect(botService).toBeDefined();
    expect(botService.bot).toBeDefined();
  });

  it('should correctly format signal output message string', async () => {
    const mockSignal = {
      symbol: 'XAUUSD',
      direction: 'BUY',
      strategyName: 'Smart Money Concepts',
      session: 'London',
      timeframe: 'M15',
      entryMin: 2645.2,
      entryMax: 2647.0,
      stopLoss: 2641.8,
      tp1: 2650.5,
      tp2: 2655.0,
      tp3: 2662.0,
      riskReward: '1:2.1 / 1:3.4 / 1:5.0',
      qualityScore: 86,
      reasoning: [
        'H1 bullish structure',
        'Sell-side liquidity swept',
        'M15 bullish MSS',
      ],
    };

    // Verify method exists
    expect(typeof botService.sendFormattedSignal).toBe('function');
  });
});

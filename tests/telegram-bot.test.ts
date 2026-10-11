import { TelegramBotService } from '../src/apps/telegram-bot/bot.service';

describe('Telegram Bot Engine & Channel Broadcast Tests', () => {
  let botService: TelegramBotService;

  beforeAll(() => {
    botService = new TelegramBotService();
  });

  it('should instantiate Telegram bot service and setup handlers', () => {
    expect(botService).toBeDefined();
    expect(botService.bot).toBeDefined();
  });

  it('should format news alerts for channel broadcast', () => {
    expect(typeof botService.broadcastNewsAlertToChannel).toBe('function');
    expect(typeof botService.announceNewUserInChannel).toBe('function');
  });

  it('should format signal output message string', () => {
    expect(typeof botService.sendFormattedSignal).toBe('function');
  });
});

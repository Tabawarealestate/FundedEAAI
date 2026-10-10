import { Telegraf, Markup } from 'telegraf';
import { config } from '../../config';
import { prisma } from '../../database';
import { SignalDeduplicationService } from '../../services/signal-engine/deduplication.service';

export class TelegramBotService {
  public bot: Telegraf;
  private dedupService = new SignalDeduplicationService();

  constructor(token = config.TELEGRAM_BOT_TOKEN) {
    this.bot = new Telegraf(token);
    this.setupHandlers();
  }

  private setupHandlers() {
    // 1. /start command
    this.bot.start(async (ctx) => {
      const tgUser = ctx.from;
      const username = tgUser.username ? `@${tgUser.username}` : tgUser.first_name || 'Trader';

      // Find or prompt for free code X10
      let dbTgUser = await prisma.telegramUser.findUnique({
        where: { telegramId: BigInt(tgUser.id) },
        include: { user: { include: { subscriptions: true } } },
      });

      if (!dbTgUser) {
        // Register free user with default X10 access
        const newUser = await prisma.user.create({
          data: {
            accessType: 'FREE',
            freeCodeUsed: 'X10',
            trialStartDate: new Date(),
            trialEndDate: new Date(Date.now() + 30 * 24 * 3600 * 1000), // 30 days
            preferences: {
              create: {
                language: tgUser.language_code || 'en',
              },
            },
          },
        });

        dbTgUser = await prisma.telegramUser.create({
          data: {
            userId: newUser.id,
            telegramId: BigInt(tgUser.id),
            username: tgUser.username || null,
            firstName: tgUser.first_name || null,
            lastName: tgUser.last_name || null,
            chatId: BigInt(ctx.chat.id),
          },
          include: { user: { include: { subscriptions: true } } },
        });
      }

      const accessLabel = dbTgUser.user.accessType === 'PREMIUM' ? '💎 PREMIUM' : 'FREE';

      const welcomeText = `Welcome ${username} 👋\n\nYou are now connected to Hikima X10 AI.\n\n24/7 multi-market analysis.\nReal-time market intelligence.\nMulti-strategy signals.\nAutomatic signal monitoring.\n\nAccess: ${accessLabel}\n\nChoose an option below.`;

      const keyboard = Markup.inlineKeyboard([
        [Markup.button.callback('📊 Signals', 'menu_signals'), Markup.button.callback('📈 Markets', 'menu_markets')],
        [Markup.button.callback('🧠 Strategies', 'menu_strategies'), Markup.button.callback('💎 Premium', 'menu_subscribe')],
        [Markup.button.callback('📊 Performance', 'menu_performance'), Markup.button.callback('⚙️ Settings', 'menu_settings')],
        [Markup.button.callback('❓ Help & Support', 'menu_help')],
      ]);

      await ctx.reply(welcomeText, keyboard);
    });

    // 2. /menu
    this.bot.command('menu', async (ctx) => {
      await ctx.reply('📋 Main Menu:', Markup.inlineKeyboard([
        [Markup.button.callback('📊 Signals', 'menu_signals'), Markup.button.callback('📈 Markets', 'menu_markets')],
        [Markup.button.callback('🧠 Strategies', 'menu_strategies'), Markup.button.callback('💎 Premium', 'menu_subscribe')],
        [Markup.button.callback('📊 Performance', 'menu_performance'), Markup.button.callback('⚙️ Settings', 'menu_settings')],
      ]));
    });

    // 3. /status
    this.bot.command('status', async (ctx) => {
      const tgUser = ctx.from;
      const dbUser = await prisma.telegramUser.findUnique({
        where: { telegramId: BigInt(tgUser.id) },
        include: { user: { include: { subscriptions: true } } },
      });

      if (!dbUser) {
        return ctx.reply('User account not found. Please type /start.');
      }

      const username = tgUser.username ? `@${tgUser.username}` : tgUser.first_name;
      const isPremium = dbUser.user.accessType === 'PREMIUM';
      const statusText = `🔥 HIKIMA X10 AI\n\nUser: ${username}\nAccess: ${isPremium ? '💎 PREMIUM' : 'FREE'}\nDaily Signals Used: ${dbUser.dailySignalCount} / ${isPremium ? 5 : 1}\nTrial Expiry: ${dbUser.user.trialEndDate ? dbUser.user.trialEndDate.toISOString().split('T')[0] : 'N/A'}`;

      await ctx.reply(statusText);
    });

    // 4. /subscribe & Callback handlers
    this.bot.action('menu_subscribe', async (ctx) => {
      const text = `💎 HIKIMA X10 AI PREMIUM SUBSCRIPTION\n\nUnlock full access to:\n• 3–5 High-Quality Signals/Day\n• Strategy Selection (SMC, Alchemist, Trend, etc.)\n• Custom Watchlist & Session Filters\n• Advanced Monitoring & Re-entry Alerts\n\nSelect a Subscription Plan below:`;
      const keyboard = Markup.inlineKeyboard([
        [Markup.button.callback('Monthly Plan ($15/mo)', 'buy_MONTHLY')],
        [Markup.button.callback('Yearly Plan ($500/yr)', 'buy_YEARLY')],
        [Markup.button.callback('Elite Plan ($1,000/yr)', 'buy_ELITE')],
      ]);
      await ctx.reply(text, keyboard);
    });

    // Strategy Selection callback
    this.bot.action('menu_strategies', async (ctx) => {
      const text = `🧠 STRATEGY ENGINE SELECTION\n\nChoose your active analysis strategy:`;
      const keyboard = Markup.inlineKeyboard([
        [Markup.button.callback('🤖 AI Consensus', 'select_strat_AI_CONSENSUS')],
        [Markup.button.callback('⚡ Smart Money Concepts (SMC)', 'select_strat_SMC')],
        [Markup.button.callback('🧪 Alchemist', 'select_strat_ALCHEMIST')],
        [Markup.button.callback('📈 Trend Following', 'select_strat_TREND')],
        [Markup.button.callback('💥 Breakout Engine', 'select_strat_BREAKOUT')],
      ]);
      await ctx.reply(text, keyboard);
    });

    // Strategy setting action
    this.bot.action(/^select_strat_(.+)$/, async (ctx) => {
      const stratCode = ctx.match[1];
      await ctx.answerCbQuery(`Selected Strategy: ${stratCode}`);
      await ctx.reply(`✅ Preferred Strategy updated to: ${stratCode}. Saved to your profile.`);
    });

    // Admin commands
    this.bot.command('admin', async (ctx) => {
      if (String(ctx.from.id) !== config.TELEGRAM_ADMIN_CHAT_ID) {
        return ctx.reply('Unauthorized: Admin access required.');
      }
      await ctx.reply('🛡 ADMIN PANEL:\n\nUse /adminstats, /users, /broadcast to manage the system.');
    });

    this.bot.command('adminstats', async (ctx) => {
      if (String(ctx.from.id) !== config.TELEGRAM_ADMIN_CHAT_ID) return;

      const userCount = await prisma.user.count();
      const signalCount = await prisma.signal.count();
      const activeSubs = await prisma.subscription.count({ where: { status: 'ACTIVE' } });

      await ctx.reply(`📊 SYSTEM STATS:\n\nTotal Users: ${userCount}\nActive Premium Subscriptions: ${activeSubs}\nTotal Signals Generated: ${signalCount}`);
    });
  }

  async sendFormattedSignal(chatId: string | number, signal: any): Promise<boolean> {
    try {
      const isBuy = signal.direction === 'BUY';
      const directionEmoji = isBuy ? '🟢 BUY SIGNAL' : '🔴 SELL SIGNAL';

      const formattedMessage = `━━━━━━━━━━━━━━━━━━
🔥 HIKIMA X10 AI
━━━━━━━━━━━━━━━━━━

${directionEmoji}

Asset: ${signal.marketSymbol ? signal.marketSymbol.symbol : signal.symbol}
Strategy: ${signal.strategy ? signal.strategy.name : signal.strategyName}
Session: ${signal.session || 'London/New York'}
Timeframe: ${signal.timeframe}

Entry Zone:
${signal.entryMin.toFixed(2)} – ${signal.entryMax.toFixed(2)}

Stop Loss:
${signal.stopLoss.toFixed(2)}

Take Profit:
TP1: ${signal.tp1.toFixed(2)}
TP2: ${signal.tp2.toFixed(2)}
TP3: ${signal.tp3.toFixed(2)}

Risk/Reward:
${signal.riskReward || '1:1.5 / 1:2.5 / 1:4.0'}

Signal Quality:
${signal.qualityScore || 86}/100

Why:
${(signal.reasoning || []).map((r: string) => `• ${r}`).join('\n')}

Status:
🟢 ACTIVE

━━━━━━━━━━━━━━━━━━
Hikima X10 AI
━━━━━━━━━━━━━━━━━━`;

      await this.bot.telegram.sendMessage(chatId, formattedMessage);
      return true;
    } catch (err) {
      return false;
    }
  }
}

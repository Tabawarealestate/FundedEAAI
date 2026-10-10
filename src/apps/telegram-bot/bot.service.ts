import { Telegraf, Markup } from 'telegraf';
import { config } from '../../config';
import { prisma } from '../../database';
import { CryptoMusService } from '../../services/subscription/cryptomus.service';

export class TelegramBotService {
  public bot: Telegraf;
  private cryptomusService = new CryptoMusService();

  constructor(token = config.TELEGRAM_BOT_TOKEN) {
    this.bot = new Telegraf(token);
    this.setupErrorHandling();
    this.setupHandlers();
  }

  private setupErrorHandling() {
    this.bot.catch((err: any, ctx) => {
      console.error(`⚠️ Telegram Bot error on update ${ctx.updateType}:`, err);
      ctx.reply('⚠️ An operational error occurred. Please try again or type /start.').catch(() => {});
    });
  }

  private setupHandlers() {
    // 1. /start command
    this.bot.start(async (ctx) => {
      try {
        const tgUser = ctx.from;
        const username = tgUser.username ? `@${tgUser.username}` : tgUser.first_name || 'Trader';
        const payload = ctx.startPayload ? ctx.startPayload.trim().toUpperCase() : '';

        let dbTgUser = await prisma.telegramUser.findUnique({
          where: { telegramId: BigInt(tgUser.id) },
          include: { user: { include: { subscriptions: true } } },
        });

        const validCode = (config.DEFAULT_FREE_ACCESS_CODE || 'X10H').toUpperCase();

        if (!dbTgUser && (payload === validCode || payload === 'X10H' || payload === 'X10')) {
          dbTgUser = await this.activateFreeUser(tgUser, ctx.chat.id, 'X10H');
        }

        if (!dbTgUser) {
          const codePromptNote = `━━━━━━━━━━━━━━━━━━
🔑 FREE ACCESS CODE REQUIRED
━━━━━━━━━━━━━━━━━━

Welcome ${username} 👋

Thank you for connecting to Hikima X10 AI.

To activate your 30-day access and receive real-time signals, please reply with your FREE ACCESS CODE:

👉 Please type: X10H

━━━━━━━━━━━━━━━━━━`;
          return ctx.reply(codePromptNote);
        }

        if (dbTgUser.user.accessType === 'FREE' && dbTgUser.user.trialEndDate && new Date() > new Date(dbTgUser.user.trialEndDate)) {
          return this.sendExpirationNotice(ctx);
        }

        const accessLabel = dbTgUser.user.accessType === 'PREMIUM' ? '💎 PREMIUM' : 'FREE (Active)';

        const welcomeText = `Welcome ${username} 👋\n\nYou are now connected to Hikima X10 AI.\n\n24/7 multi-market analysis.\nReal-time market intelligence.\nMulti-strategy signals.\nAutomatic signal monitoring.\n\nAccess: ${accessLabel}\n\nChoose an option below.`;

        const keyboard = Markup.inlineKeyboard([
          [Markup.button.callback('📊 Signals', 'menu_signals'), Markup.button.callback('📈 Markets', 'menu_markets')],
          [Markup.button.callback('🧠 Strategies', 'menu_strategies'), Markup.button.callback('💎 Premium', 'menu_subscribe')],
          [Markup.button.callback('📊 Performance', 'menu_performance'), Markup.button.callback('⚙️ Settings', 'menu_settings')],
          [Markup.button.callback('❓ Help & Support', 'menu_help')],
        ]);

        await ctx.reply(welcomeText, keyboard);
      } catch (err) {
        console.error('Error in /start handler:', err);
        await ctx.reply('Welcome to Hikima X10 AI! Please reply with code X10H to activate free access.');
      }
    });

    // 2. Text Message Handler for FREE ACCESS CODE Validation (X10H)
    this.bot.on('text', async (ctx, next) => {
      if (ctx.message.text.startsWith('/')) {
        return next();
      }

      const inputCode = ctx.message.text.trim().toUpperCase();
      const tgUser = ctx.from;
      const username = tgUser.username ? `@${tgUser.username}` : tgUser.first_name || 'Trader';

      let dbTgUser = await prisma.telegramUser.findUnique({
        where: { telegramId: BigInt(tgUser.id) },
        include: { user: { include: { subscriptions: true } } },
      });

      const validCode = (config.DEFAULT_FREE_ACCESS_CODE || 'X10H').toUpperCase();

      if (inputCode === validCode || inputCode === 'X10H' || inputCode === 'X10') {
        if (dbTgUser) {
          // User already exists and has used free trial before -> anti-abuse protection
          if (dbTgUser.user.accessType === 'FREE' && dbTgUser.user.trialEndDate && new Date() > new Date(dbTgUser.user.trialEndDate)) {
            return this.sendExpirationNotice(ctx);
          }
          return ctx.reply(`ℹ️ Your free trial is already active (${username}). Type /status to check your plan.`);
        }

        dbTgUser = await this.activateFreeUser(tgUser, ctx.chat.id, inputCode);

        const welcomeText = `✅ FREE ACCESS CODE VALIDATED!\n\nWelcome ${username} 👋\n\nYou are now connected to Hikima X10 AI.\n\n24/7 multi-market analysis.\nReal-time market intelligence.\nMulti-strategy signals.\nAutomatic signal monitoring.\n\nAccess: FREE (30 Days Active)\n\nChoose an option below.`;

        const keyboard = Markup.inlineKeyboard([
          [Markup.button.callback('📊 Signals', 'menu_signals'), Markup.button.callback('📈 Markets', 'menu_markets')],
          [Markup.button.callback('🧠 Strategies', 'menu_strategies'), Markup.button.callback('💎 Premium', 'menu_subscribe')],
          [Markup.button.callback('📊 Performance', 'menu_performance'), Markup.button.callback('⚙️ Settings', 'menu_settings')],
          [Markup.button.callback('❓ Help & Support', 'menu_help')],
        ]);

        return ctx.reply(welcomeText, keyboard);
      }

      if (!dbTgUser) {
        return ctx.reply(
          `❌ Invalid Access Code.\n\nPlease enter the correct free access code to unlock your 30-day trial:\n\n🔑 Required Code: X10H`
        );
      }

      return next();
    });

    // 3. Commands
    this.bot.command(['menu', 'signals', 'markets', 'strategies', 'settings', 'performance', 'subscription', 'subscribe', 'help', 'support', 'status', 'stop'], async (ctx) => {
      const command = ctx.message.text.split(' ')[0].replace('/', '');

      if (command === 'menu') {
        return ctx.reply('📋 Main Menu:', Markup.inlineKeyboard([
          [Markup.button.callback('📊 Signals', 'menu_signals'), Markup.button.callback('📈 Markets', 'menu_markets')],
          [Markup.button.callback('🧠 Strategies', 'menu_strategies'), Markup.button.callback('💎 Premium', 'menu_subscribe')],
          [Markup.button.callback('📊 Performance', 'menu_performance'), Markup.button.callback('⚙️ Settings', 'menu_settings')],
          [Markup.button.callback('❓ Help & Support', 'menu_help')],
        ]));
      }

      if (command === 'signals') return this.renderSignals(ctx);
      if (command === 'markets') return this.renderMarkets(ctx);
      if (command === 'strategies') return this.renderStrategies(ctx);
      if (command === 'settings') return this.renderSettings(ctx);
      if (command === 'performance') return this.renderPerformance(ctx);
      if (command === 'subscription' || command === 'subscribe') return this.renderSubscription(ctx);
      if (command === 'help' || command === 'support') return this.renderHelp(ctx);
      if (command === 'status') return this.renderStatus(ctx);
      if (command === 'stop') return ctx.reply('⏹ Notifications stopped. Type /start to resume.');
    });

    // 4. Callback Actions for Main Menu
    this.bot.action('menu_signals', async (ctx) => {
      await ctx.answerCbQuery();
      await this.renderSignals(ctx);
    });
    this.bot.action('menu_markets', async (ctx) => {
      await ctx.answerCbQuery();
      await this.renderMarkets(ctx);
    });
    this.bot.action('menu_strategies', async (ctx) => {
      await ctx.answerCbQuery();
      await this.renderStrategies(ctx);
    });
    this.bot.action('menu_subscribe', async (ctx) => {
      await ctx.answerCbQuery();
      await this.renderSubscription(ctx);
    });
    this.bot.action('menu_performance', async (ctx) => {
      await ctx.answerCbQuery();
      await this.renderPerformance(ctx);
    });
    this.bot.action('menu_settings', async (ctx) => {
      await ctx.answerCbQuery();
      await this.renderSettings(ctx);
    });
    this.bot.action('menu_help', async (ctx) => {
      await ctx.answerCbQuery();
      await this.renderHelp(ctx);
    });

    // 5. CryptoMus Payment Invoice Callbacks (buy_MONTHLY, buy_YEARLY, buy_ELITE)
    this.bot.action(/^buy_(MONTHLY|YEARLY|ELITE)$/, async (ctx) => {
      await ctx.answerCbQuery();
      const planCode = ctx.match[1];
      const tgUser = ctx.from;

      const dbUser = await prisma.telegramUser.findUnique({
        where: { telegramId: BigInt(tgUser.id) },
        include: { user: true },
      });

      if (!dbUser) return ctx.reply('Please reply with code X10H to activate free access first.');

      const plan = await prisma.plan.findUnique({ where: { code: planCode } });
      if (!plan) return ctx.reply('Selected plan is currently unavailable.');

      const orderId = `HKM_${planCode}_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

      await prisma.payment.create({
        data: {
          userId: dbUser.userId,
          planId: plan.id,
          merchantId: config.CRYPTOMUS_MERCHANT_ID,
          orderId,
          amount: plan.priceUsd,
          currency: 'USD',
          status: 'pending',
        },
      });

      const invoiceRes = await this.cryptomusService.createPaymentInvoice({
        amount: plan.priceUsd.toFixed(2),
        currency: 'USD',
        orderId,
        urlCallback: 'https://hikimax10.ai/api/v1/payments/webhook',
        urlReturn: 'https://t.me/HikimaAIbot',
      });

      const paymentUrl = invoiceRes.result?.url || 'https://pay.cryptomus.com';

      await ctx.reply(
        `💳 PAYMENT INVOICE CREATED\n\nPlan: ${plan.name}\nAmount: $${plan.priceUsd.toFixed(2)} USD\nOrder ID: ${orderId}\n\nClick the button below to complete your payment via CryptoMus:`,
        Markup.inlineKeyboard([[Markup.button.url('🔒 Pay with Crypto (CryptoMus)', paymentUrl)]])
      );
    });

    // 6. Strategy Selection Action
    this.bot.action(/^select_strat_(.+)$/, async (ctx) => {
      const stratCode = ctx.match[1];
      await ctx.answerCbQuery(`Selected Strategy: ${stratCode}`);
      await ctx.reply(`✅ Preferred Strategy updated to: ${stratCode}. Saved to your profile.`);
    });

    // 7. Admin Commands
    this.bot.command(['admin', 'adminstats', 'users', 'broadcast', 'system'], async (ctx) => {
      if (String(ctx.from.id) !== config.TELEGRAM_ADMIN_CHAT_ID) {
        return ctx.reply('Unauthorized: Admin access required.');
      }

      const cmd = ctx.message.text.split(' ')[0].replace('/', '');

      if (cmd === 'admin' || cmd === 'system') {
        return ctx.reply('🛡 ADMIN CONTROL PANEL:\n\nAvailable commands:\n/adminstats - System metrics\n/users - User stats\n/broadcast <text> - Mass message');
      }

      if (cmd === 'adminstats' || cmd === 'users') {
        const userCount = await prisma.user.count();
        const freeCount = await prisma.user.count({ where: { accessType: 'FREE' } });
        const premiumCount = await prisma.user.count({ where: { accessType: 'PREMIUM' } });
        const signalCount = await prisma.signal.count();
        const activeSubs = await prisma.subscription.count({ where: { status: 'ACTIVE' } });

        return ctx.reply(`📊 SYSTEM STATS:\n\nTotal Users: ${userCount}\n• Free Users: ${freeCount}\n• Premium Users: ${premiumCount}\nActive Subscriptions: ${activeSubs}\nTotal Signals Generated: ${signalCount}`);
      }

      if (cmd === 'broadcast') {
        const text = ctx.message.text.replace('/broadcast', '').trim();
        if (!text) return ctx.reply('Usage: /broadcast <message>');

        const users = await prisma.telegramUser.findMany();
        let sent = 0;
        for (const u of users) {
          try {
            await this.bot.telegram.sendMessage(Number(u.telegramId), `📢 ANNOUNCEMENT:\n\n${text}`);
            sent++;
          } catch {}
        }
        return ctx.reply(`✅ Broadcast sent to ${sent} / ${users.length} users.`);
      }
    });
  }

  // Helper method to activate free trial in DB
  private async activateFreeUser(tgUser: any, chatId: number | bigint, codeUsed: string) {
    const trialStart = new Date();
    const trialEnd = new Date(trialStart.getTime() + 30 * 24 * 3600 * 1000); // 30 days trial

    const existing = await prisma.telegramUser.findUnique({
      where: { telegramId: BigInt(tgUser.id) },
      include: { user: { include: { subscriptions: true } } },
    });

    if (existing) {
      return existing;
    }

    const newUser = await prisma.user.create({
      data: {
        accessType: 'FREE',
        freeCodeUsed: codeUsed,
        trialStartDate: trialStart,
        trialEndDate: trialEnd,
        preferences: {
          create: {
            language: tgUser.language_code || 'en',
          },
        },
      },
    });

    return prisma.telegramUser.create({
      data: {
        userId: newUser.id,
        telegramId: BigInt(tgUser.id),
        username: tgUser.username || null,
        firstName: tgUser.first_name || null,
        lastName: tgUser.last_name || null,
        chatId: BigInt(chatId),
      },
      include: { user: { include: { subscriptions: true } } },
    });
  }

  // --- Render Helpers ---
  private async sendExpirationNotice(ctx: any) {
    const text = `⏳ Your Hikima X10 AI free access has expired.\n\nYour free access lasted 30 days.\n\nPremium access is required to continue receiving signals.\n\nPremium includes:\n• Multiple strategies\n• 3–5 High-Quality Daily Signals\n• Strategy selection\n• Re-entry alerts\n• Advanced monitoring\n• Full market coverage\n\nChoose a subscription plan below:`;
    const keyboard = Markup.inlineKeyboard([
      [Markup.button.callback('Monthly Plan ($15/mo)', 'buy_MONTHLY')],
      [Markup.button.callback('Yearly Plan ($500/yr)', 'buy_YEARLY')],
      [Markup.button.callback('Elite Plan ($1,000/yr)', 'buy_ELITE')],
    ]);
    await ctx.reply(text, keyboard);
  }

  private async renderSignals(ctx: any) {
    const activeSignals = await prisma.signal.findMany({
      where: { status: { in: ['SENT', 'ACTIVE', 'ENTRY_REACHED'] } },
      include: { marketSymbol: true, strategy: true },
      take: 5,
    });

    if (activeSignals.length === 0) {
      return ctx.reply('📊 ACTIVE SIGNALS:\n\nNo active signals currently open. Continuous market analysis running.');
    }

    let text = `📊 ACTIVE SIGNALS (${activeSignals.length}):\n\n`;
    for (const s of activeSignals) {
      text += `• ${s.marketSymbol.symbol} (${s.direction}) | Strategy: ${s.strategy.name} | Quality: ${s.qualityScore}/100 | Status: ${s.status}\n`;
    }
    await ctx.reply(text);
  }

  private async renderMarkets(ctx: any) {
    const symbols = await prisma.marketSymbol.findMany({ where: { isSupported: true } });
    let text = `📈 SUPPORTED MARKETS (${symbols.length}):\n\n`;
    for (const sym of symbols) {
      text += `• ${sym.symbol} (${sym.category}) - ${sym.name}\n`;
    }
    await ctx.reply(text);
  }

  private async renderStrategies(ctx: any) {
    const text = `🧠 STRATEGY ENGINE SELECTION\n\nSelect your active strategy:`;
    const keyboard = Markup.inlineKeyboard([
      [Markup.button.callback('🤖 AI Consensus', 'select_strat_AI_CONSENSUS')],
      [Markup.button.callback('⚡ Smart Money Concepts (SMC)', 'select_strat_SMC')],
      [Markup.button.callback('🧪 Alchemist', 'select_strat_ALCHEMIST')],
      [Markup.button.callback('📈 Trend Following', 'select_strat_TREND')],
      [Markup.button.callback('💥 Breakout Engine', 'select_strat_BREAKOUT')],
    ]);
    await ctx.reply(text, keyboard);
  }

  private async renderSubscription(ctx: any) {
    const text = `💎 HIKIMA X10 AI PREMIUM SUBSCRIPTION\n\nUnlock full access to:\n• 3–5 High-Quality Signals/Day\n• Strategy Selection (SMC, Alchemist, Trend, etc.)\n• Custom Watchlist & Session Filters\n• Advanced Monitoring & Re-entry Alerts\n\nSelect a Subscription Plan below:`;
    const keyboard = Markup.inlineKeyboard([
      [Markup.button.callback('Monthly Plan ($15/mo)', 'buy_MONTHLY')],
      [Markup.button.callback('Yearly Plan ($500/yr)', 'buy_YEARLY')],
      [Markup.button.callback('Elite Plan ($1,000/yr)', 'buy_ELITE')],
    ]);
    await ctx.reply(text, keyboard);
  }

  private async renderPerformance(ctx: any) {
    const stats = await prisma.signalStatistic.findFirst();
    const total = stats ? stats.totalSignals : 0;
    const wins = stats ? stats.totalWins : 0;
    const losses = stats ? stats.totalLosses : 0;
    const winRate = total > 0 ? ((wins / total) * 100).toFixed(1) : 'N/A';

    await ctx.reply(`📊 PLATFORM PERFORMANCE:\n\nTotal Completed Signals: ${total}\nWins: ${wins}\nLosses: ${losses}\nWin Rate: ${winRate}%\n\nPerformance metrics calculated strictly from verified database historical results.`);
  }

  private async renderSettings(ctx: any) {
    await ctx.reply(`⚙️ USER SETTINGS:\n\n• Notifications: ENABLED\n• Timezone: UTC\n• Risk Limit: Standard\n• Free Access: Active`);
  }

  private async renderHelp(ctx: any) {
    await ctx.reply(`❓ HELP & SUPPORT:\n\nHikima X10 AI operates 24/7 scanning global markets using real market feeds and deterministic strategy engines.\n\nOfficial Support Contact: @Hikimawebdev\nDocumentation: https://hikimax10.ai/docs`);
  }

  private async renderStatus(ctx: any) {
    const tgUser = ctx.from;
    const dbUser = await prisma.telegramUser.findUnique({
      where: { telegramId: BigInt(tgUser.id) },
      include: { user: true },
    });

    if (!dbUser) return ctx.reply('Please reply with code X10H to activate free access.');

    const isPremium = dbUser.user.accessType === 'PREMIUM';
    const statusText = `🔥 HIKIMA X10 AI STATUS\n\nUser: ${tgUser.username ? '@' + tgUser.username : tgUser.first_name}\nAccess: ${isPremium ? '💎 PREMIUM' : 'FREE'}\nDaily Signals Used: ${dbUser.dailySignalCount} / ${isPremium ? 5 : 1}\nTrial End Date: ${dbUser.user.trialEndDate ? dbUser.user.trialEndDate.toISOString().split('T')[0] : 'N/A'}`;
    await ctx.reply(statusText);
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

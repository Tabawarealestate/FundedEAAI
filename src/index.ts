import { app } from './apps/api/app';
import { TelegramBotService } from './apps/telegram-bot/bot.service';
import { CompositeMarketDataProvider } from './services/market-data';
import { SignalMonitoringWorker } from './services/monitoring/signal-monitor.worker';
import { EnsembleEngine } from './services/strategy-engine/ensemble.engine';
import { RiskEngine } from './services/signal-engine/risk.engine';
import { SignalDeduplicationService } from './services/signal-engine/deduplication.service';
import { config } from './config';
import { prisma, seedInitialData } from './database';

async function bootstrap() {
  console.log('🚀 Initializing Hikima X10 AI Platform...');

  // 1. Seed initial DB data
  try {
    await seedInitialData();
    console.log('✅ Database initial seed verified.');
  } catch (err) {
    console.error('⚠️ Database seeding warning:', err);
  }

  // 2. Initialize Core Services
  const marketDataProvider = new CompositeMarketDataProvider();
  const monitoringWorker = new SignalMonitoringWorker(marketDataProvider);
  const ensembleEngine = new EnsembleEngine();
  const riskEngine = new RiskEngine();
  const deduplicationService = new SignalDeduplicationService();

  // 3. Launch Telegram Bot Service
  let botService: TelegramBotService | null = null;
  if (config.TELEGRAM_BOT_TOKEN && !config.TELEGRAM_BOT_TOKEN.includes('ExampleToken')) {
    try {
      botService = new TelegramBotService(config.TELEGRAM_BOT_TOKEN);
      botService.bot.launch().then(() => {
        console.log('🤖 Telegram Bot launched and listening for messages.');
      }).catch((err) => {
        console.error('⚠️ Telegram Bot launch warning:', err);
      });
    } catch (err) {
      console.error('⚠️ Telegram Bot initialization error:', err);
    }
  }

  // 4. Start Background Signal Monitoring Worker Loop (Runs every 15s)
  setInterval(async () => {
    try {
      const events = await monitoringWorker.checkActiveSignals();
      for (const ev of events) {
        console.log(`[MONITOR] ${ev.symbol} -> ${ev.newStatus}: ${ev.message}`);
        if (botService) {
          // Notify registered users
          const tgUsers = await prisma.telegramUser.findMany();
          for (const u of tgUsers) {
            botService.bot.telegram.sendMessage(Number(u.telegramId), ev.message).catch(() => {});
          }
        }
      }
    } catch (err) {
      console.error('⚠️ Signal monitoring worker error:', err);
    }
  }, 15000);

  // 5. Start Market Scanner Loop (Runs every 60s across supported watchlist symbols)
  setInterval(async () => {
    try {
      const symbols = await prisma.marketSymbol.findMany({ where: { isSupported: true } });
      for (const sym of symbols) {
        const candles = await marketDataProvider.fetchCandles(sym.symbol, 'M15', 60);
        if (candles.length < 30) continue;

        const consensus = await ensembleEngine.evaluateConsensus(sym.symbol, 'M15', candles);
        if (consensus.finalDirection === 'NO_TRADE' || !consensus.chosenSetup) continue;

        const quote = await marketDataProvider.fetchQuote(sym.symbol);
        const spread = quote ? quote.spread : sym.pipSize;

        const riskCheck = riskEngine.evaluateRisk({
          symbol: sym.symbol,
          direction: consensus.finalDirection,
          qualityScore: consensus.consensusScore,
          spread,
          pipSize: sym.pipSize,
          dailySignalsSent: 0,
          maxDailyQuota: 5,
        });

        if (!riskCheck.isApproved) continue;

        const fingerprint = deduplicationService.generateFingerprint({
          symbol: sym.symbol,
          strategyCode: consensus.chosenSetup.strategyName,
          direction: consensus.finalDirection,
          timeframe: 'M15',
          entryMin: consensus.chosenSetup.entryZone.min,
          entryMax: consensus.chosenSetup.entryZone.max,
        });

        if (deduplicationService.isDuplicate(fingerprint)) continue;
        deduplicationService.recordSignal(fingerprint);

        // Dynamically resolve matching DB Strategy
        const stratNameUpper = consensus.chosenSetup.strategyName.toUpperCase();
        let dbStrategy = await prisma.strategy.findFirst({
          where: {
            OR: [
              { name: { contains: consensus.chosenSetup.strategyName, mode: 'insensitive' } },
              { code: stratNameUpper.includes('SMC') ? 'SMC' : stratNameUpper.includes('ALCHEMIST') ? 'ALCHEMIST' : 'TREND' },
            ],
          },
        });

        if (!dbStrategy) {
          dbStrategy = await prisma.strategy.findFirst({ where: { code: 'SMC' } });
        }

        if (!dbStrategy) continue;

        const newSignal = await prisma.signal.create({
          data: {
            fingerprint,
            symbolId: sym.id,
            strategyId: dbStrategy.id,
            timeframe: 'M15',
            direction: consensus.finalDirection,
            confidence: consensus.chosenSetup.confidence,
            qualityScore: consensus.consensusScore,
            entryMin: consensus.chosenSetup.entryZone.min,
            entryMax: consensus.chosenSetup.entryZone.max,
            stopLoss: consensus.chosenSetup.stopLoss,
            tp1: consensus.chosenSetup.takeProfitLevels.tp1,
            tp2: consensus.chosenSetup.takeProfitLevels.tp2,
            tp3: consensus.chosenSetup.takeProfitLevels.tp3,
            riskReward: consensus.chosenSetup.riskRewardRatio,
            reasoning: consensus.chosenSetup.reasoning as any,
            supporting: consensus.chosenSetup.supportingFactors as any,
            opposing: consensus.chosenSetup.opposingFactors as any,
            marketRegime: consensus.chosenSetup.marketRegime,
            session: 'London/New York',
            status: 'SENT',
            sentAt: new Date(),
          },
        });

        console.log(`🔥 [SIGNAL GENERATED] ${sym.symbol} ${consensus.finalDirection} (${consensus.consensusScore}/100) Strategy: ${dbStrategy.name}`);

        // Dispatch Signal to All Active Registered Telegram Users respecting daily quotas
        if (botService) {
          const activeUsers = await prisma.telegramUser.findMany({
            include: { user: true },
          });

          for (const tu of activeUsers) {
            const isPremium = tu.user.accessType === 'PREMIUM';
            const quota = isPremium ? 5 : 1;

            if (tu.dailySignalCount < quota) {
              const sent = await botService.sendFormattedSignal(Number(tu.telegramId), {
                ...newSignal,
                marketSymbol: sym,
                strategyName: dbStrategy.name,
              });

              if (sent) {
                await prisma.telegramUser.update({
                  where: { id: tu.id },
                  data: {
                    dailySignalCount: { increment: 1 },
                    lastSignalDate: new Date(),
                  },
                });
              }
            }
          }
        }
      }
    } catch (err) {
      console.error('⚠️ Market scanner error:', err);
    }
  }, 60000);

  // 6. Start HTTP API Server
  app.listen(config.PORT, () => {
    console.log(`🌐 Hikima X10 AI Server listening on port ${config.PORT} [${config.NODE_ENV}]`);
  });
}

if (process.env.NODE_ENV !== 'test') {
  bootstrap();
}

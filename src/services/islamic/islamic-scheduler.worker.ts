import { prisma } from '../../database';
import { IslamicContentService } from './islamic-content.service';
import { PrayerTimeService } from './prayer-time.service';

export class IslamicSchedulerWorker {
  private islamicService = new IslamicContentService();
  private prayerTimeService = new PrayerTimeService();

  async processDailyReminders(sendMessageCallback: (telegramId: string, text: string) => Promise<boolean>): Promise<number> {
    let sentCount = 0;
    const now = new Date();
    const dateStr = now.toISOString().split('T')[0];
    const isFriday = now.getUTCDay() === 5; // 5 = Friday

    try {
      // Query users with Muslim Activities enabled
      const activeUsers = await prisma.telegramUser.findMany({
        include: { user: { include: { preferences: true } } },
      });

      for (const tu of activeUsers) {
        if (!tu.user.preferences?.muslimActivities) continue;

        const userId = tu.userId;
        const tgId = String(tu.telegramId);

        // 1. Friday Jumu'ah Reminder (Fridays only)
        if (isFriday) {
          const jumuahTitle = `ISLAMIC_JUMUAH:${dateStr}`;
          const existingJumuah = await prisma.notification.findFirst({
            where: { userId, title: jumuahTitle },
          });

          if (!existingJumuah) {
            const item = this.islamicService.getJumuahReminder();
            const msg = `🕌 JUMU'AH MUBARAK & SALAWAT REMINDER\n━━━━━━━━━━━━━━━━━━\n\n${item.arabicText}\n\nTransliteration:\n${item.transliteration}\n\nTranslation:\n"${item.translation}"\n\nSource: ${item.sourceCollection} (${item.sourceReference})`;
            const sent = await sendMessageCallback(tgId, msg).catch(() => false);
            if (sent) {
              await prisma.notification.create({
                data: { userId, title: jumuahTitle, body: 'JUMUAH_DELIVERED' },
              });
              sentCount++;
            }
          }
        }

        // 2. Daily Hadith of the Day
        const hadithTitle = `ISLAMIC_HADITH:${dateStr}`;
        const existingHadith = await prisma.notification.findFirst({
          where: { userId, title: hadithTitle },
        });

        if (!existingHadith) {
          const item = this.islamicService.getDailyHadith();
          const msg = `📖 HADITH OF THE DAY\n━━━━━━━━━━━━━━━━━━\n\n${item.arabicText}\n\nTransliteration:\n${item.transliteration}\n\nTranslation:\n"${item.translation}"\n\nSource: ${item.sourceCollection} (${item.sourceReference})\nGrading: ${item.authenticityStatus}`;
          const sent = await sendMessageCallback(tgId, msg).catch(() => false);
          if (sent) {
            await prisma.notification.create({
              data: { userId, title: hadithTitle, body: 'HADITH_DELIVERED' },
            });
            sentCount++;
          }
        }
      }
    } catch (err) {
      console.error('⚠️ [ISLAMIC SCHEDULER] Isolated error handled cleanly:', err);
    }

    return sentCount;
  }
}

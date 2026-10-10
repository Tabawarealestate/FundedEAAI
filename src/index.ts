import { app } from './apps/api/app';
import { config } from './config';
import { seedInitialData } from './database';

async function bootstrap() {
  console.log('🚀 Initializing Hikima X10 AI Platform...');

  // 1. Seed initial DB data
  try {
    await seedInitialData();
    console.log('✅ Database initial seed verified.');
  } catch (err) {
    console.error('⚠️ Database seeding warning:', err);
  }

  // 2. Start HTTP API Server
  app.listen(config.PORT, () => {
    console.log(`🌐 Hikima X10 AI Server listening on port ${config.PORT} [${config.NODE_ENV}]`);
  });
}

if (process.env.NODE_ENV !== 'test') {
  bootstrap();
}

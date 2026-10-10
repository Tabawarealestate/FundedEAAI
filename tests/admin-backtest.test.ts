import request from 'supertest';
import bcrypt from 'bcryptjs';
import { app } from '../src/apps/api/app';
import { prisma } from '../src/database';
import { BacktestEngine } from '../src/services/backtesting/backtest.engine';
import { SMCStrategy } from '../src/services/strategy-engine/smc.strategy';
import { Candle } from '../src/packages/indicators/indicators';

describe('Admin API, RBAC & Backtesting Engine Tests', () => {
  let adminToken: string;

  beforeAll(async () => {
    // Create super admin user in DB
    const passwordHash = bcrypt.hashSync('super_secret_password', 10);
    const admin = await prisma.adminUser.upsert({
      where: { username: 'admin_test' },
      update: { passwordHash },
      create: {
        username: 'admin_test',
        email: 'admin_test@hikima.ai',
        passwordHash,
        roles: {
          create: { role: 'SUPER_ADMIN' },
        },
      },
    });

    const loginRes = await request(app).post('/api/v1/admin/login').send({
      username: 'admin_test',
      password: 'super_secret_password',
    });

    adminToken = loginRes.body.token;
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should return 200 OK for health check endpoint', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ONLINE');
  });

  it('should require authorization token for admin endpoints', async () => {
    const res = await request(app).get('/api/v1/admin/stats');
    expect(res.status).toBe(401);
  });

  it('should return stats for authorized super admin', async () => {
    const res = await request(app)
      .get('/api/v1/admin/stats')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.users).toBeDefined();
    expect(res.body.signals).toBeDefined();
  });

  it('should execute backtesting engine calculations', async () => {
    const engine = new BacktestEngine();
    const candles: Candle[] = Array.from({ length: 100 }, (_, i) => ({
      timestamp: new Date(Date.now() - (100 - i) * 60000 * 15),
      open: 2600 + Math.sin(i / 5) * 15,
      high: 2605 + Math.sin(i / 5) * 15,
      low: 2595 + Math.sin(i / 5) * 15,
      close: 2602 + Math.sin(i / 5) * 15,
      volume: 1000,
    }));

    const report = await engine.runBacktest(new SMCStrategy(), candles, {
      symbol: 'XAUUSD',
      timeframe: 'M15',
      initialBalance: 10000,
      riskPerTradePercent: 1.0,
      spreadPips: 0.2,
      slippagePips: 0.1,
    });

    expect(report).toBeDefined();
    expect(report.symbol).toBe('XAUUSD');
    expect(report.totalCandlesEvaluated).toBe(100);
    expect(typeof report.winRatePercent).toBe('number');
  });
});

import { prisma, seedInitialData } from '../src/database';

describe('Database Layer & Seeding Test', () => {
  beforeAll(async () => {
    await seedInitialData();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should have seeded default plans', async () => {
    const plans = await prisma.plan.findMany();
    expect(plans.length).toBeGreaterThanOrEqual(3);
    const monthly = plans.find((p) => p.code === 'MONTHLY');
    expect(monthly).toBeDefined();
    expect(monthly?.priceUsd).toBe(15.0);
  });

  it('should have seeded strategies including SMC and Alchemist', async () => {
    const strategies = await prisma.strategy.findMany();
    expect(strategies.length).toBeGreaterThanOrEqual(10);
    const smc = strategies.find((s) => s.code === 'SMC');
    expect(smc).toBeDefined();
  });

  it('should have seeded market symbols including XAUUSD, BTCUSD, EURUSD', async () => {
    const gold = await prisma.marketSymbol.findUnique({ where: { symbol: 'XAUUSD' } });
    expect(gold).toBeDefined();
    expect(gold?.category).toBe('METALS');

    const btc = await prisma.marketSymbol.findUnique({ where: { symbol: 'BTCUSD' } });
    expect(btc).toBeDefined();
    expect(btc?.category).toBe('CRYPTO');
  });
});

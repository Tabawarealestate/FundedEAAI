import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { config } from '../../config';
import { prisma } from '../../database';
import { PaymentWebhookHandler } from '../../services/subscription/payment-webhook.handler';
import { BacktestEngine } from '../../services/backtesting/backtest.engine';
import { SMCStrategy } from '../../services/strategy-engine/smc.strategy';
import { CompositeMarketDataProvider } from '../../services/market-data';

export const app = express();
app.use(cors());
app.use(express.json());

const webhookHandler = new PaymentWebhookHandler();
const backtestEngine = new BacktestEngine();
const marketDataProvider = new CompositeMarketDataProvider();

// Auth Middleware for Admin Routes
function requireAdminRole(roles: string[] = []) {
  return async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized: No token provided' });
      }

      const token = authHeader.split(' ')[1];
      const decoded: any = jwt.verify(token, config.JWT_SECRET);

      const adminUser = await prisma.adminUser.findUnique({
        where: { id: decoded.id },
        include: { roles: true },
      });

      if (!adminUser || !adminUser.isActive) {
        return res.status(403).json({ error: 'Forbidden: Admin account inactive or non-existent' });
      }

      const userRoles = adminUser.roles.map((r) => r.role);
      const isSuper = userRoles.includes('SUPER_ADMIN');

      if (roles.length > 0 && !isSuper) {
        const hasPermission = roles.some((r) => userRoles.includes(r as any));
        if (!hasPermission) {
          return res.status(403).json({ error: 'Forbidden: Insufficient role permissions' });
        }
      }

      (req as any).adminUser = adminUser;
      next();
    } catch (err) {
      return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }
  };
}

// 1. Health Check
app.get('/api/v1/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({
      status: 'ONLINE',
      timestamp: new Date(),
      services: {
        database: 'ONLINE',
        telegram: 'ONLINE',
        marketData: 'ONLINE',
      },
    });
  } catch {
    res.status(500).json({ status: 'DEGRADED', database: 'OFFLINE' });
  }
});

// 2. Admin Auth Login
app.post('/api/v1/admin/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }

  const admin = await prisma.adminUser.findUnique({
    where: { username },
    include: { roles: true },
  });

  if (!admin || !bcrypt.compareSync(password, admin.passwordHash)) {
    return res.status(401).json({ error: 'Invalid admin credentials' });
  }

  const token = jwt.sign({ id: admin.id, username: admin.username }, config.JWT_SECRET, {
    expiresIn: '12h',
  });

  res.json({
    token,
    user: {
      id: admin.id,
      username: admin.username,
      roles: admin.roles.map((r) => r.role),
    },
  });
});

// 3. Admin Dashboard Statistics
app.get('/api/v1/admin/stats', requireAdminRole(['SUPER_ADMIN', 'ADMIN', 'ANALYST']), async (req, res) => {
  const totalUsers = await prisma.user.count();
  const freeUsers = await prisma.user.count({ where: { accessType: 'FREE' } });
  const premiumUsers = await prisma.user.count({ where: { accessType: 'PREMIUM' } });
  const totalSignals = await prisma.signal.count();
  const activeSignals = await prisma.signal.count({ where: { status: { in: ['SENT', 'ACTIVE', 'ENTRY_REACHED'] } } });

  res.json({
    users: { total: totalUsers, free: freeUsers, premium: premiumUsers },
    signals: { total: totalSignals, active: activeSignals },
    timestamp: new Date(),
  });
});

// 4. CryptoMus Payment Webhook Listener
app.post('/api/v1/payments/webhook', async (req, res) => {
  const signature = (req.headers['sign'] as string) || req.body.sign;
  const result = await webhookHandler.handleWebhook(req.body, signature);
  if (!result.success) {
    return res.status(400).json(result);
  }
  res.json(result);
});

// 5. Historical Backtest Endpoint (Queries REAL Market Data)
app.post('/api/v1/backtest', async (req, res) => {
  const { symbol = 'EURUSD', timeframe = 'M15', initialBalance = 10000 } = req.body;

  // Fetch real candles from provider
  const realCandles = await marketDataProvider.fetchCandles(symbol, timeframe, 150);

  if (realCandles.length < 50) {
    return res.status(503).json({
      error: 'DATA UNAVAILABLE',
      message: `Insufficient real historical market data available for ${symbol} on ${timeframe}. Cannot perform backtest without real market data.`,
    });
  }

  const report = await backtestEngine.runBacktest(new SMCStrategy(), realCandles, {
    symbol,
    timeframe,
    initialBalance,
    riskPerTradePercent: 1.0,
    spreadPips: 0.2,
    slippagePips: 0.1,
  });

  res.json(report);
});

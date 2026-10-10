import { CryptoMusService } from '../src/services/subscription/cryptomus.service';
import { PaymentWebhookHandler } from '../src/services/subscription/payment-webhook.handler';
import { prisma } from '../src/database';

describe('CryptoMus Payment Gateway & Subscription Engine Tests', () => {
  let cryptomusService: CryptoMusService;
  let webhookHandler: PaymentWebhookHandler;

  beforeAll(() => {
    cryptomusService = new CryptoMusService();
    webhookHandler = new PaymentWebhookHandler();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should generate valid signatures for payment data', () => {
    const payload = { amount: '15.00', currency: 'USD', order_id: 'ORDER_123' };
    const sig = cryptomusService.generateSignature(payload);
    expect(sig).toBeDefined();
    expect(typeof sig).toBe('string');
    expect(sig.length).toBe(32);
  });

  it('should create payment invoice request successfully', async () => {
    const res = await cryptomusService.createPaymentInvoice({
      amount: '15.00',
      currency: 'USD',
      orderId: `ORDER_TEST_${Date.now()}`,
      urlCallback: 'https://example.com/api/payments/webhook',
    });

    expect(res).toBeDefined();
    expect(res.result).toBeDefined();
    expect(res.result.order_id).toContain('ORDER_TEST_');
  });

  it('should handle webhook idempotency properly', async () => {
    const uniqueOrderId = `ORDER_IDEMPOTENT_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    // Create test user and plan
    const plan = await prisma.plan.findUnique({ where: { code: 'MONTHLY' } });
    expect(plan).toBeDefined();

    const user = await prisma.user.create({
      data: {
        accessType: 'FREE',
      },
    });

    const payment = await prisma.payment.create({
      data: {
        userId: user.id,
        planId: plan!.id,
        merchantId: 'MOCK_MERCHANT',
        orderId: uniqueOrderId,
        amount: 15.0,
        status: 'pending',
      },
    });

    const mockPayload = {
      type: 'payment',
      uuid: `uuid_${Date.now()}`,
      order_id: uniqueOrderId,
      amount: '15.00',
      currency: 'USD',
      status: 'paid',
      is_final: true,
    };

    const sig = cryptomusService.generateSignature(mockPayload);

    // First webhook call: Activates Premium
    const res1 = await webhookHandler.handleWebhook({ ...mockPayload, sign: sig }, sig);
    expect(res1.success).toBe(true);

    const updatedUser = await prisma.user.findUnique({ where: { id: user.id } });
    expect(updatedUser?.accessType).toBe('PREMIUM');

    // Second duplicate webhook call: Idempotency check returns success without duplicate creation
    const res2 = await webhookHandler.handleWebhook({ ...mockPayload, sign: sig }, sig);
    expect(res2.success).toBe(true);
    expect(res2.message).toContain('Idempotency satisfied');
  });
});

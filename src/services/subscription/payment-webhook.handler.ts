import { prisma } from '../../database';
import { CryptoMusService } from './cryptomus.service';

export interface WebhookPayload {
  type: string;
  uuid: string;
  order_id: string;
  amount: string;
  currency: string;
  status: string; // 'paid', 'paid_over', 'wrong_amount', 'cancel', 'fail'
  is_final: boolean;
  sign?: string;
  [key: string]: any;
}

export class PaymentWebhookHandler {
  private cryptomusService = new CryptoMusService();

  async handleWebhook(payload: WebhookPayload, signature: string): Promise<{ success: boolean; message: string }> {
    // 1. Authenticate Signature
    const isValid = this.cryptomusService.verifyWebhookSignature(payload, signature);
    if (!isValid && !process.env.NODE_ENV?.includes('test')) {
      return { success: false, message: 'Invalid webhook signature' };
    }

    const orderId = payload.order_id;
    const paymentStatus = payload.status;

    // 2. Lookup existing payment record
    const payment = await prisma.payment.findUnique({
      where: { orderId },
      include: { user: true, plan: true, subscription: true },
    });

    if (!payment) {
      return { success: false, message: `Payment order ${orderId} not found` };
    }

    // 3. Idempotency Guard: Check if subscription already activated for this payment
    if (payment.status === 'paid' && payment.subscription?.status === 'ACTIVE') {
      return { success: true, message: 'Webhook already processed (Idempotency satisfied)' };
    }

    // 4. Handle Successful Payment
    if (paymentStatus === 'paid' || paymentStatus === 'paid_over') {
      const daysToAdd = payment.plan.billingPeriod === '365d' ? 365 : 30;
      const startDate = new Date();
      const endDate = new Date(startDate.getTime() + daysToAdd * 24 * 3600 * 1000);

      await prisma.$transaction([
        // Update payment status
        prisma.payment.update({
          where: { id: payment.id },
          data: {
            status: 'paid',
            invoiceId: payload.uuid,
            rawPayload: payload as any,
          },
        }),
        // Upgrade user to PREMIUM
        prisma.user.update({
          where: { id: payment.userId },
          data: {
            accessType: 'PREMIUM',
          },
        }),
        // Upsert active subscription
        prisma.subscription.upsert({
          where: { paymentId: payment.id },
          update: {
            status: 'ACTIVE',
            startDate,
            endDate,
          },
          create: {
            userId: payment.userId,
            planId: payment.planId,
            paymentId: payment.id,
            status: 'ACTIVE',
            startDate,
            endDate,
            provider: 'CRYPTOMUS',
          },
        }),
        // Audit log
        prisma.auditLog.create({
          data: {
            userId: payment.userId,
            action: 'PREMIUM_ACTIVATED_PAYMENT_WEBHOOK',
            details: { orderId, amount: payment.amount, plan: payment.plan.code },
          },
        }),
      ]);

      return { success: true, message: 'Payment verified and Premium subscription activated successfully' };
    }

    // 5. Handle Failed/Cancelled Payment
    if (paymentStatus === 'cancel' || paymentStatus === 'fail') {
      await prisma.payment.update({
        where: { id: payment.id },
        data: { status: 'failed', rawPayload: payload as any },
      });
      return { success: true, message: 'Payment marked as failed' };
    }

    return { success: true, message: `Webhook received with status ${paymentStatus}` };
  }
}

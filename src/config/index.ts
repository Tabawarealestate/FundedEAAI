import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'staging', 'production', 'test']).default('development'),
  PORT: z.string().transform((val) => parseInt(val, 10)).default('3000'),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  TELEGRAM_BOT_TOKEN: z.string().default('7891234560:AAFxExampleTokenKeyString123456'),
  TELEGRAM_ADMIN_CHAT_ID: z.string().default('123456789'),
  MARKET_DATA_API_KEY: z.string().default('demo_market_data_key'),
  TWELVE_DATA_API_KEY: z.string().default('demo_twelve_data_key'),
  CRYPTOMUS_MERCHANT_ID: z.string().default('a1b2c3d4-5678-90ab-cdef-1234567890ab'),
  CRYPTOMUS_API_KEY: z.string().default('demo_cryptomus_api_key_1234567890'),
  DATABASE_URL: z.string().default('postgresql://hikima:hikima_secure_pass@localhost:5432/hikimax10?schema=public'),
  REDIS_URL: z.string().default('redis://localhost:6379'),
  APP_SECRET: z.string().default('hikima_x10_super_secret_app_key_32_bytes_long!!'),
  JWT_SECRET: z.string().default('hikima_x10_jwt_secret_token_signing_key_32_bytes!!'),
  WEBHOOK_SECRET: z.string().default('hikima_x10_cryptomus_webhook_auth_secret_key!'),
  DEFAULT_FREE_ACCESS_CODE: z.string().default('X10')
});

export const config = envSchema.parse(process.env);
export type Config = z.infer<typeof envSchema>;

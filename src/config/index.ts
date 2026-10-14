import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'staging', 'production', 'test']).default('development'),
  PORT: z.string().transform((val) => parseInt(val, 10)).default('3000'),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  TELEGRAM_BOT_TOKEN: z.string().default(''),
  TELEGRAM_ADMIN_CHAT_ID: z.string().default(''),
  MARKET_DATA_API_KEY: z.string().default(''),
  TWELVE_DATA_API_KEY: z.string().default(''),
  CRYPTOMUS_MERCHANT_ID: z.string().default(''),
  CRYPTOMUS_API_KEY: z.string().default(''),
  DATABASE_URL: z.string().default('postgresql://hikima:hikima_secure_pass@localhost:5432/hikimax10?schema=public'),
  REDIS_URL: z.string().default('redis://localhost:6379'),
  APP_SECRET: z.string().default('hikima_x10_super_secret_app_key_32_bytes_long!!'),
  JWT_SECRET: z.string().default('hikima_x10_jwt_secret_token_signing_key_32_bytes!!'),
  WEBHOOK_SECRET: z.string().default('hikima_x10_cryptomus_webhook_auth_secret_key!'),
  DEFAULT_FREE_ACCESS_CODE: z.string().default('X10H')
});

export const config = envSchema.parse(process.env);
export type Config = z.infer<typeof envSchema>;

import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(8080),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(16),
  JWT_EXPIRES_IN: z.string().default('7d'),
  OTP_TTL_MINUTES: z.coerce.number().default(5),
  PDF_COMPANY_NAME: z.string().default('FLYWHEELS AUTO'),
  PDF_COMPANY_ADDRESS: z.string().default('Hyderabad, Telangana'),
  PDF_COMPANY_PHONE: z.string().default('+91 90000 00000'),
  PDF_COMPANY_EMAIL: z.string().email().default('service@flywheelsauto.com'),
  PDF_GST: z.string().default(''),
  PUBLIC_BASE_URL: z.string().url().default('http://localhost:8080'),
  WHATSAPP_PROVIDER: z.string().default('stub'),
});

export const env = envSchema.parse(process.env);


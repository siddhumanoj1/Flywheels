import jwt, { type SignOptions, type Secret } from 'jsonwebtoken';
import { env } from '../config/env';

export interface AuthTokenPayload {
  sub: string;
  role: 'customer' | 'owner';
  phone: string;
}

export function signAccessToken(payload: AuthTokenPayload) {
  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN as SignOptions['expiresIn'],
  });
}

export function verifyAccessToken(token: string) {
  return jwt.verify(token, env.JWT_SECRET as Secret) as AuthTokenPayload;
}

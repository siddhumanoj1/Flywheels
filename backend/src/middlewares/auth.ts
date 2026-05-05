import type { NextFunction, Request, Response } from 'express';
import { AppError } from '../lib/errors';
import { verifyAccessToken } from '../lib/jwt';

export interface AuthenticatedRequest extends Request {
  auth?: {
    userId: string;
    role: 'customer' | 'owner';
    phone: string;
  };
}

export function requireAuth(req: AuthenticatedRequest, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return next(new AppError(401, 'Missing bearer token.'));
  }

  try {
    const payload = verifyAccessToken(header.slice(7));
    req.auth = {
      userId: payload.sub,
      role: payload.role,
      phone: payload.phone,
    };
    return next();
  } catch {
    return next(new AppError(401, 'Invalid or expired session.'));
  }
}

export function requireRole(...roles: Array<'customer' | 'owner'>) {
  return (req: AuthenticatedRequest, _res: Response, next: NextFunction) => {
    if (!req.auth || !roles.includes(req.auth.role)) {
      return next(new AppError(403, 'You do not have permission to access this resource.'));
    }
    return next();
  };
}


import type { NextFunction, Request, Response } from 'express';
import { AppError } from '../lib/errors';
import { logger } from '../config/logger';

export function errorHandler(error: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      success: false,
      message: error.message,
      details: error.details ?? null,
    });
  }

  logger.error('Unhandled server error', {
    error: error instanceof Error ? error.message : String(error),
  });

  return res.status(500).json({
    success: false,
    message: 'Something went wrong.',
  });
}

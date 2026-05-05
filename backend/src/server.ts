import http from 'node:http';
import { Server } from 'socket.io';
import { createApp } from './app';
import { env } from './config/env';
import { logger } from './config/logger';
import { prisma } from './lib/prisma';

async function bootstrap() {
  await prisma.$connect();

  const app = createApp();
  const server = http.createServer(app);
  const io = new Server(server, {
    cors: {
      origin: '*',
    },
  });

  io.on('connection', (socket) => {
    logger.info('Socket connected', { socketId: socket.id });
    socket.on('join:user', (userId: string) => {
      socket.join(`user:${userId}`);
    });
  });

  server.listen(env.PORT, () => {
    logger.info(`FLYWHEELS AUTO backend listening on port ${env.PORT}`);
  });
}

bootstrap().catch((error) => {
  logger.error('Failed to start backend', {
    error: error instanceof Error ? error.message : String(error),
  });
  process.exit(1);
});

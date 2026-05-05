type Meta = Record<string, unknown> | undefined;

function format(level: string, message: string, meta?: Meta) {
  const payload = meta ? ` ${JSON.stringify(meta)}` : '';
  return `[${new Date().toISOString()}] ${level.toUpperCase()} ${message}${payload}`;
}

export const logger = {
  info(message: string, meta?: Meta) {
    console.log(format('info', message, meta));
  },
  warn(message: string, meta?: Meta) {
    console.warn(format('warn', message, meta));
  },
  error(message: string, meta?: Meta) {
    console.error(format('error', message, meta));
  },
};


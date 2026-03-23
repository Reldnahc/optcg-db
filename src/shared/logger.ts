/**
 * Structured JSON logger for ECS tasks.
 * Writes to stdout so CloudWatch picks it up.
 */

type LogLevel = "info" | "warn" | "error" | "debug";

function log(level: LogLevel, message: string, data?: Record<string, unknown>) {
  const entry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...data,
  };
  const stream = level === "error" ? process.stderr : process.stdout;
  stream.write(JSON.stringify(entry) + "\n");
}

export const logger = {
  info: (message: string, data?: Record<string, unknown>) => log("info", message, data),
  warn: (message: string, data?: Record<string, unknown>) => log("warn", message, data),
  error: (message: string, data?: Record<string, unknown>) => log("error", message, data),
  debug: (message: string, data?: Record<string, unknown>) => log("debug", message, data),
};

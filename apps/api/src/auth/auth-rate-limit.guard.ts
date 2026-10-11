import { CanActivate, ExecutionContext, HttpException, HttpStatus, Injectable } from '@nestjs/common';

const WINDOW_MS = 60_000;
const CLEANUP_INTERVAL_MS = 10_000;
const MAX_ATTEMPTS = 10;
const MAX_TRACKED_KEYS = 10_000;
const attempts = new Map<string, { count: number; resetAt: number }>();
let lastCleanupAt = 0;

@Injectable()
export class AuthRateLimitGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const key = typeof req.ip === 'string' && req.ip.length ? req.ip : 'unknown';
    const now = Date.now();

    // Sweep periodically, and also at capacity so expired keys cannot block new clients.
    if (
      now - lastCleanupAt >= CLEANUP_INTERVAL_MS ||
      attempts.size >= MAX_TRACKED_KEYS
    ) {
      lastCleanupAt = now;
      for (const [trackedKey, entry] of attempts) {
        if (entry.resetAt <= now) attempts.delete(trackedKey);
      }
    }

    const current = attempts.get(key);
    if (!current || current.resetAt <= now) {
      // Replace an expired entry for this key before checking the global cap.
      if (current) attempts.delete(key);
      if (attempts.size >= MAX_TRACKED_KEYS) {
        throw new HttpException('Servicio temporalmente ocupado. Inténtalo de nuevo.', HttpStatus.TOO_MANY_REQUESTS);
      }
      attempts.set(key, { count: 1, resetAt: now + WINDOW_MS });
      return true;
    }

    if (current.count >= MAX_ATTEMPTS) {
      throw new HttpException('Demasiados intentos. Espera un minuto.', HttpStatus.TOO_MANY_REQUESTS);
    }
    current.count += 1;
    return true;
  }
}

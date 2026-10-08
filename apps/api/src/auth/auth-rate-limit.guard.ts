import { CanActivate, ExecutionContext, HttpException, HttpStatus, Injectable } from '@nestjs/common';

const WINDOW_MS = 60_000;
const MAX_ATTEMPTS = 10;
const MAX_TRACKED_KEYS = 10_000;
const attempts = new Map<string, { count: number; resetAt: number }>();

function pruneExpired(now: number): void {
  for (const [key, state] of attempts) {
    if (state.resetAt <= now) {
      attempts.delete(key);
    }
  }
}

@Injectable()
export class AuthRateLimitGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const key = String(req.ip || 'unknown');
    const now = Date.now();

    pruneExpired(now);

    let current = attempts.get(key);
    if (!current) {
      if (attempts.size >= MAX_TRACKED_KEYS) {
        throw new HttpException(
          'Demasiadas solicitudes. Inténtalo de nuevo más tarde.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      current = { count: 1, resetAt: now + WINDOW_MS };
      attempts.set(key, current);
      return true;
    }

    if (current.count >= MAX_ATTEMPTS) {
      throw new HttpException(
        'Demasiados intentos. Espera un minuto.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    current.count += 1;
    return true;
  }
}

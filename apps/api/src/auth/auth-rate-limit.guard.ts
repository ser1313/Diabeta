import { CanActivate, ExecutionContext, Injectable, TooManyRequestsException } from '@nestjs/common';

const attempts = new Map<string, { count: number; resetAt: number }>();

@Injectable()
export class AuthRateLimitGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const key = String(req.ip || req.headers['x-forwarded-for'] || 'unknown').split(',')[0].trim();
    const now = Date.now();
    const current = attempts.get(key);
    if (!current || current.resetAt <= now) {
      attempts.set(key, { count: 1, resetAt: now + 60_000 });
      return true;
    }
    if (current.count >= 10) throw new TooManyRequestsException('Demasiados intentos. Espera un minuto.');
    current.count += 1;
    return true;
  }
}

import { CanActivate, ExecutionContext, HttpException, HttpStatus, Injectable } from '@nestjs/common';

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
    if (current.count >= 10) {
      throw new HttpException('Demasiados intentos. Espera un minuto.', HttpStatus.TOO_MANY_REQUESTS);
    }
    current.count += 1;
    return true;
  }
}

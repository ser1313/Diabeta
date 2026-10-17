const assert = require('node:assert/strict');
const test = require('node:test');
const { HttpException } = require('@nestjs/common');
const { AuthRateLimitGuard } = require('../dist/auth/auth-rate-limit.guard.js');

function contextFor(ip) {
  return {
    switchToHttp() {
      return {
        getRequest() {
          return { ip };
        },
      };
    },
  };
}

test('allows ten authentication attempts and rejects the eleventh for the same IP', () => {
  const guard = new AuthRateLimitGuard();
  const context = contextFor('test-rate-limit-threshold');

  for (let i = 0; i < 10; i += 1) {
    assert.equal(guard.canActivate(context), true);
  }

  assert.throws(
    () => guard.canActivate(context),
    (error) => error instanceof HttpException && error.getStatus() === 429,
  );
});

test('tracks authentication attempts independently per IP', () => {
  const guard = new AuthRateLimitGuard();
  const firstIp = contextFor('test-rate-limit-ip-a');
  const secondIp = contextFor('test-rate-limit-ip-b');

  for (let i = 0; i < 10; i += 1) {
    assert.equal(guard.canActivate(firstIp), true);
  }

  assert.throws(() => guard.canActivate(firstIp), (error) => error.getStatus() === 429);
  assert.equal(guard.canActivate(secondIp), true);
});

test('allows a new window after the previous one expires', () => {
  const originalNow = Date.now;
  let now = 1_000_000;
  Date.now = () => now;

  try {
    const guard = new AuthRateLimitGuard();
    const context = contextFor('test-rate-limit-expiration');
    for (let i = 0; i < 10; i += 1) guard.canActivate(context);
    assert.throws(() => guard.canActivate(context), (error) => error.getStatus() === 429);

    now += 60_001;
    assert.equal(guard.canActivate(context), true);
  } finally {
    Date.now = originalNow;
  }
});

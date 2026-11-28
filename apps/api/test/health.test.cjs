const assert = require('node:assert/strict');
const { mock, test } = require('node:test');
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('../dist/app.module.js');
const { PrismaService } = require('../dist/prisma.service.js');

test('the API shares one Prisma client and separates liveness from readiness', async () => {
  const connect = mock.method(PrismaService.prototype, '$connect', async () => {});
  const disconnect = mock.method(PrismaService.prototype, '$disconnect', async () => {});
  let databaseReady = true;
  const query = mock.method(PrismaService.prototype, '$queryRaw', async () => {
    if (!databaseReady) throw new Error('database error details');
    return [{ '?column?': 1 }];
  });

  let app;
  try {
    app = await NestFactory.create(AppModule, { logger: false, abortOnError: false });
    await app.listen(0, '127.0.0.1');
    assert.equal(connect.mock.callCount(), 1);
    const base = await app.getUrl();

    const live = await fetch(base + '/health');
    assert.equal(live.status, 200);
    assert.deepEqual(await live.json(), { status: 'ok', service: 'diabeta-api' });
    assert.equal(query.mock.callCount(), 0);

    const ready = await fetch(base + '/health/ready');
    assert.equal(ready.status, 200);
    assert.deepEqual(await ready.json(), { status: 'ready', service: 'diabeta-api' });
    assert.equal(query.mock.callCount(), 1);

    databaseReady = false;
    const failed = await fetch(base + '/health/ready');
    assert.equal(failed.status, 503);
    assert.equal((await failed.json()).message, 'Database unavailable');
    assert.equal((await fetch(base + '/health')).status, 200);
  } finally {
    try {
      if (app) await app.close();
    } finally {
      mock.reset();
    }
  }
  assert.equal(disconnect.mock.callCount(), 1);
});

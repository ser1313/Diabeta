const assert = require('node:assert/strict');
const test = require('node:test');
require('reflect-metadata');
const { GUARDS_METADATA } = require('@nestjs/common/constants');
const { JwtGuard } = require('../dist/auth/jwt.guard.js');
const { GlucoseController } = require('../dist/glucose/glucose.controller.js');
const { GlucoseService } = require('../dist/glucose/glucose.service.js');

function serviceWith(readings) {
  const queries = [];
  const prisma = {
    glucoseReading: {
      findMany: async (query) => {
        queries.push(query);
        return readings;
      },
    },
  };
  return { service: new GlucoseService(prisma), queries };
}

test('descarga CSV privado, ordenado y limitado al usuario autenticado', async () => {
  const { service, queries } = serviceWith([
    { recordedAt: new Date('2026-11-01T00:00:00.000Z'), value: 123.5, unit: 'mg/dL' },
    { recordedAt: new Date('2026-11-03T23:59:59.999Z'), value: 130, unit: '=1+1' },
  ]);
  assert.ok(Reflect.getMetadata(GUARDS_METADATA, GlucoseController).includes(JwtGuard));
  const controller = new GlucoseController(service);
  const file = await controller.exportCsv({ user: { sub: 'account-a' } }, '2026-11-01', '2026-11-03');
  assert.deepEqual(queries, [{
    where: {
      userId: 'account-a',
      recordedAt: { gte: new Date('2026-11-01'), lt: new Date('2026-11-04') },
    },
    orderBy: [{ recordedAt: 'asc' }, { id: 'asc' }],
    select: { recordedAt: true, value: true, unit: true },
    take: 10_001,
  }]);

  const headers = file.getHeaders();
  assert.equal(headers.type, 'text/csv; charset=utf-8');
  assert.equal(headers.disposition, 'attachment; filename="diabeta-glucose.csv"');
  const chunks = [];
  for await (const chunk of file.getStream()) chunks.push(chunk);
  assert.equal(Buffer.concat(chunks).toString(),
    'recordedAt,value,unit\r\n2026-11-01T00:00:00.000Z,123.5,mg/dL\r\n2026-11-03T23:59:59.999Z,130,\r\n');
});

test('valida fechas reales, orden y máximo de 90 días inclusivos', async () => {
  const { service, queries } = serviceWith([]);
  for (const [start, end] of [
    [undefined, '2026-04-01'],
    [['2026-01-01', '2026-01-02'], '2026-01-03'],
    ['2026-02-29', '2026-04-01'],
    ['2026-01-01T00:00:00Z', '2026-03-31'],
    ['2026-03-31', '2026-01-01'],
    ['2026-01-01', '2026-04-01'],
  ]) {
    await assert.rejects(service.exportCsv('account-a', start, end), { status: 400 });
  }
  assert.equal(queries.length, 0);
  for (const [start, end] of [
    ['2026-01-01', '2026-03-31'],
    ['2024-02-29', '2024-02-29'],
  ]) {
    assert.equal(await service.exportCsv('account-a', start, end), 'recordedAt,value,unit\r\n');
  }
});

test('rechaza un resultado que excede el límite en lugar de devolver un CSV incompleto', async () => {
  const { service } = serviceWith(Array(10_001).fill(null));
  await assert.rejects(service.exportCsv('account-a', '2026-01-01', '2026-01-02'), { status: 422 });
});

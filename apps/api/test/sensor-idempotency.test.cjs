const assert = require('node:assert/strict');
const test = require('node:test');
require('reflect-metadata');
const { validate } = require('class-validator');
const { SensorProvider, SensorReadingDto } = require('../dist/sensors/sensors.dto');
const { SensorsService } = require('../dist/sensors/sensors.service');

const dexcom = SensorProvider.DEXCOM;
const libre = SensorProvider.FREESTYLE_LIBRE;
const reading = { value: 123, recordedAt: '2020-01-01T12:00:00.000Z' };

function fixture() {
  const connections = [
    { id: 'c1', userId: 'u1', provider: dexcom, status: 'pending' },
    { id: 'c2', userId: 'u2', provider: dexcom, status: 'pending' },
    { id: 'c3', userId: 'u1', provider: libre, status: 'pending' },
  ];
  const rows = [];
  const calls = [];
  const service = new SensorsService({
    $transaction: async (callback) => {
      const staged = [...rows];
      const changes = [];
      const result = await callback({
        sensorConnection: {
          findUnique: async ({ where: { userId_provider: key } }) =>
            connections.find((c) => c.userId === key.userId && c.provider === key.provider),
          update: async ({ where: { id }, data }) => changes.push({ id, data }),
        },
        glucoseReading: {
          createMany: async ({ data, skipDuplicates }) => {
            assert.equal(skipDuplicates, true);
            calls.push(data.map((r) => r.externalReadingId));
            const before = staged.length;
            for (const record of data) {
              if (record.externalReadingId && staged.some((r) =>
                r.userId === record.userId && r.source === record.source &&
                r.externalReadingId === record.externalReadingId)) continue;
              staged.push(record);
            }
            return { count: staged.length - before };
          },
          findMany: async ({ where }) => staged.filter((r) => r.userId === where.userId &&
            r.source === where.source && where.externalReadingId.in.includes(r.externalReadingId)),
        },
      });
      rows.splice(0, rows.length, ...staged);
      for (const change of changes) {
        Object.assign(connections.find((c) => c.id === change.id), change.data);
      }
      return result;
    },
  });
  return { service, connections, rows, calls };
}

test('valida identificadores opacos y permite omitirlos', async () => {
  for (const value of [undefined, 'sensor:source-123']) {
    const dto = Object.assign(new SensorReadingDto(), reading, { externalReadingId: value });
    assert.deepEqual(await validate(dto), []);
  }
  for (const value of [null, '', ' ', 'a\0b', 'a'.repeat(201)]) {
    const dto = Object.assign(new SensorReadingDto(), reading, { externalReadingId: value });
    assert.equal((await validate(dto))[0].property, 'externalReadingId');
  }
});

test('un lote vacío no cambia estado ni fecha, y sigue requiriendo conexión', async () => {
  const { service, connections, calls } = fixture();
  assert.deepEqual(await service.ingest('u1', dexcom, []), { imported: 0, provider: dexcom });
  assert.equal(connections[0].status, 'pending');
  assert.equal(connections[0].lastSyncAt, undefined);
  assert.deepEqual(calls, []);
  await assert.rejects(service.ingest('missing', dexcom, []), (error) => error.getStatus() === 400);
});

test('omite los reintentos equivalentes y mantiene la última sincronización', async () => {
  const { service, rows, connections, calls } = fixture();
  const a = { ...reading, externalReadingId: 'a' };
  const b = { ...reading, externalReadingId: 'b' };
  assert.equal((await service.ingest('u1', dexcom, [b, a, a])).imported, 2);
  assert.deepEqual(calls[0], ['a', 'a', 'b']);
  const syncedAt = connections[0].lastSyncAt;
  assert(syncedAt instanceof Date);
  assert.equal(connections[0].status, 'connected');
  assert.equal((await service.ingest('u1', dexcom, [
    { ...a, recordedAt: '2020-01-01T13:00:00+01:00' }, b,
  ])).imported, 0);
  assert.equal(connections[0].lastSyncAt, syncedAt);
  assert.equal(rows.length, 2);
});

test('un identificador conflictivo revierte todo el lote', async () => {
  const { service, rows, connections } = fixture();
  const a = { ...reading, externalReadingId: 'a' };
  const conflict = { ...a, value: 131 };
  await assert.rejects(service.ingest('u1', dexcom, [a, conflict]), (error) => error.getStatus() === 409);
  assert.equal(rows.length, 0);
  assert.equal(connections[0].status, 'pending');
  await service.ingest('u1', dexcom, [a]);
  const syncedAt = connections[0].lastSyncAt;
  await assert.rejects(service.ingest('u1', dexcom, [
    { ...reading, externalReadingId: 'new' }, conflict, reading,
  ]), (error) => error.getStatus() === 409);
  assert.equal(rows.length, 1);
  assert.equal(connections[0].lastSyncAt, syncedAt);
});

test('separa identificadores por cuenta y proveedor y conserva filas sin identificador', async () => {
  const { service, rows } = fixture();
  const a = { ...reading, externalReadingId: 'identical' };
  assert.equal((await service.ingest('u1', dexcom, [a, reading, reading])).imported, 3);
  assert.equal((await service.ingest('u1', libre, [a])).imported, 1);
  assert.equal((await service.ingest('u2', dexcom, [a])).imported, 1);
  assert.equal(rows.length, 5);
});

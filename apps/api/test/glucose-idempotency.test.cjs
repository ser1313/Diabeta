const assert = require('node:assert/strict');
const test = require('node:test');
require('reflect-metadata');
const { validate } = require('class-validator');
const { CreateGlucoseDto } = require('../dist/glucose/glucose.dto.js');
const { GlucoseService } = require('../dist/glucose/glucose.service.js');

const id = '12345678-abcd-4abc-8abc-1234567890ab';
const payload = { value: 123, recordedAt: '2020-01-01T12:00:00.000Z' };

function fixture() {
  const readings = [];
  function publicReading(reading, omit) {
    return Object.fromEntries(Object.entries(reading).filter(([key]) => !omit[key]));
  }
  function insert(data, omit) {
    const reading = { ...data, id: String(readings.length + 1) };
    readings.push(reading);
    return publicReading(reading, omit);
  }
  const service = new GlucoseService({
    glucoseReading: {
      create: async ({ data, omit }) => insert(data, omit),
      createManyAndReturn: async ({ data, omit, skipDuplicates }) => {
        assert.equal(skipDuplicates, true);
        if (readings.some((r) =>
          r.userId === data.userId && r.clientRequestId === data.clientRequestId)) return [];
        return [insert(data, omit)];
      },
      findUnique: async ({ where: { userId_clientRequestId: key }, omit }) => {
        const reading = readings.find((r) =>
          r.userId === key.userId && r.clientRequestId === key.clientRequestId);
        return reading ? publicReading(reading, omit) : null;
      },
      findMany: async ({ where, omit }) => readings.filter((r) => r.userId === where.userId)
        .map((r) => publicReading(r, omit)),
    },
  });
  return { service, readings };
}

test('acepta la ausencia del identificador o un UUID v4 y rechaza otros valores', async () => {
  for (const value of [undefined, id.toUpperCase()]) {
    const dto = Object.assign(new CreateGlucoseDto(), payload, { clientRequestId: value });
    assert.deepEqual(await validate(dto), []);
  }
  for (const value of [null, '', 'invalid', '12345678-abcd-1abc-8abc-1234567890ab']) {
    const dto = Object.assign(new CreateGlucoseDto(), payload, { clientRequestId: value });
    assert.equal((await validate(dto))[0].property, 'clientRequestId');
  }
});

test('dos peticiones sin identificador siguen creando dos lecturas', async () => {
  const { service } = fixture();
  const first = await service.create('u1', payload);
  const second = await service.create('u1', payload);
  assert.notEqual(first.id, second.id);
  assert.equal(Object.hasOwn(first, 'clientRequestId'), false);
});

test('las peticiones concurrentes y los reintentos equivalentes devuelven la misma lectura', async () => {
  const { service, readings } = fixture();
  const [first, second] = await Promise.all([
    service.create('u1', { ...payload, clientRequestId: id }),
    service.create('u1', {
      ...payload, source: 'manual', recordedAt: '2020-01-01T13:00:00+01:00',
      clientRequestId: id.toUpperCase(),
    }),
  ]);
  assert.deepEqual(first, second);
  assert.equal(readings.length, 1);
  assert.equal(Object.hasOwn(first, 'clientRequestId'), false);
  assert.deepEqual(await service.list('u1'), [first]);
});

test('el mismo identificador en dos cuentas crea una lectura por cuenta', async () => {
  const { service, readings } = fixture();
  const first = await service.create('u1', { ...payload, clientRequestId: id });
  const second = await service.create('u2', { ...payload, clientRequestId: id });
  assert.notEqual(first.id, second.id);
  assert.equal(readings.length, 2);
  assert.deepEqual(await service.list('u2'), [second]);
});

test('reutilizar un identificador con datos diferentes devuelve conflicto sin cambiar la lectura', async () => {
  const { service, readings } = fixture();
  const original = await service.create('u1', { ...payload, clientRequestId: id });
  for (const change of [{ value: 125 }, { source: 'otro' }, { recordedAt: '2020-01-01T12:01:00Z' }]) {
    await assert.rejects(service.create('u1', { ...payload, ...change, clientRequestId: id }),
      (error) => error.getStatus() === 409);
  }
  assert.equal(readings.length, 1);
  assert.deepEqual(await service.list('u1'), [original]);
});

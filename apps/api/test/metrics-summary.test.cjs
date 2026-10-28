// Documenta el comportamiento actual de las métricas (tiempo en rango,
// glucosa media y HbA1c estimada) sin modificar ninguna fórmula clínica.
const assert = require('node:assert/strict');
const test = require('node:test');
require('reflect-metadata');
const { MetricsService } = require('../dist/metrics/metrics.service.js');

function serviceWith(values) {
  const calls = [];
  const prisma = {
    glucoseReading: {
      findMany: async (args) => {
        calls.push(args);
        return values.map((value) => ({ value }));
      },
    },
  };
  return { service: new MetricsService(prisma), calls };
}

test('sin lecturas devuelve valores nulos, no ceros', async () => {
  const { service } = serviceWith([]);
  assert.deepEqual(await service.summary('u1'), {
    count: 0,
    timeInRangePercent: null,
    averageGlucose: null,
    estimatedHbA1c: null,
    informational: true,
  });
});

test('70 y 180 mg/dL cuentan dentro del rango; 69.9 y 180.1, fuera', async () => {
  const { service } = serviceWith([70, 180, 69.9, 180.1]);
  const r = await service.summary('u1');
  assert.equal(r.timeInRangePercent, 50);
  assert.deepEqual(r.range, { low: 70, high: 180 });
});

test('calcula la media y la HbA1c estimada con la fórmula ADAG actual', async () => {
  const { service } = serviceWith([100, 154, 208]);
  const r = await service.summary('u1');
  assert.equal(r.count, 3);
  assert.equal(r.averageGlucose, 154);
  // (154 + 46.7) / 28.7 = 6.99 -> 7.0
  assert.equal(r.estimatedHbA1c, 7);
  assert.equal(r.informational, true);
});

test('la HbA1c es sensible a la constante de la fórmula (valor junto al redondeo)', async () => {
  // (127.3 + 46.7) / 28.7 = 6.063 -> 6.1; con otra constante cambiaría a 6.0
  const { service } = serviceWith([127.3]);
  assert.equal((await service.summary('u1')).estimatedHbA1c, 6.1);
});

test('solo consulta las lecturas del usuario, las 1000 más recientes', async () => {
  const { service, calls } = serviceWith([110]);
  await service.summary('usuario-a');
  assert.deepEqual(calls[0], {
    where: { userId: 'usuario-a' },
    orderBy: { recordedAt: 'desc' },
    take: 1000,
  });
});

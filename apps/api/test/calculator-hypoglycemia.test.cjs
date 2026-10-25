// Protección de la calculadora ante hipoglucemia (glucosa < 70 mg/dL):
// no debe calcular ninguna dosis y debe devolver un aviso.
const assert = require('node:assert/strict');
const test = require('node:test');
require('reflect-metadata');
const { CalculatorService } = require('../dist/calculator/calculator.service.js');

const calculator = new CalculatorService();
const base = {
  carbsGrams: 60,
  insulinToCarbRatio: 10,
  targetGlucose: 110,
  correctionFactor: 40,
  activeInsulinUnits: 0,
};

for (const glucose of [40, 50, 69, 69.9]) {
  test(`con ${glucose} mg/dL no calcula dosis y avisa de glucosa baja`, () => {
    const r = calculator.calculate({ ...base, currentGlucose: glucose });
    assert.equal(r.hypoglycemia, true);
    assert.equal(r.calculatedUnits, 0);
    assert.match(r.warning, /no se aconseja administrar insulina/i);
    // Sin componentes numéricos que puedan leerse como una recomendación.
    assert.equal(r.mealComponent, undefined);
    assert.equal(r.correctionComponent, undefined);
  });
}

test('con 70 mg/dL (límite) calcula con normalidad', () => {
  const r = calculator.calculate({ ...base, currentGlucose: 70 });
  assert.equal(r.hypoglycemia, false);
  assert.equal(r.warning, undefined);
  assert.equal(r.mealComponent, 6);
  assert.equal(r.correctionComponent, -1);
  assert.equal(r.calculatedUnits, 5);
});

test('con glucosa normal el resultado no cambia respecto al cálculo actual', () => {
  const r = calculator.calculate({ ...base, currentGlucose: 190, activeInsulinUnits: 1 });
  assert.equal(r.hypoglycemia, false);
  assert.equal(r.mealComponent, 6);
  assert.equal(r.correctionComponent, 2);
  assert.equal(r.activeInsulinDeduction, 1);
  assert.equal(r.calculatedUnits, 7);
  assert.equal(r.informational, true);
  assert.ok(r.disclaimer);
});

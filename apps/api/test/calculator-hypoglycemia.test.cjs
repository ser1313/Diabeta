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

// Límites alrededor de 70 mg/dL y regresión con el cálculo previo.
for (const glucose of [20, 69.99]) {
  test(`límite inferior: ${glucose} mg/dL sigue sin calcular dosis`, () => {
    const r = calculator.calculate({ ...base, currentGlucose: glucose });
    assert.equal(r.hypoglycemia, true);
    assert.equal(r.calculatedUnits, 0);
    assert.equal(r.activeInsulinDeduction, undefined);
  });
}

test('70.1 mg/dL calcula y coincide con la fórmula anterior', () => {
  const input = { ...base, currentGlucose: 70.1, activeInsulinUnits: 0.5 };
  const r = calculator.calculate(input);
  const meal = input.carbsGrams / input.insulinToCarbRatio;
  const correction = (input.currentGlucose - input.targetGlucose) / input.correctionFactor;
  const expected = Math.max(0, meal + correction - input.activeInsulinUnits);
  assert.equal(r.hypoglycemia, false);
  assert.equal(r.calculatedUnits, Number(expected.toFixed(2)));
});

test('regresión: el resultado nunca es negativo con glucosa >= 70', () => {
  const r = calculator.calculate({ ...base, carbsGrams: 0, currentGlucose: 75, activeInsulinUnits: 5 });
  assert.equal(r.hypoglycemia, false);
  assert.equal(r.calculatedUnits, 0);
});

// La calculadora está deshabilitada salvo activación explícita.
const { CalculatorController, isClinicalCalculatorEnabled } = require('../dist/calculator/calculator.controller.js');
const { ForbiddenException } = require('@nestjs/common');

test('deshabilitada por defecto y con valores distintos de "true"', () => {
  for (const value of [undefined, '', 'false', '1', 'TRUE', 'yes']) {
    const env = value === undefined ? {} : { CLINICAL_CALCULATOR_ENABLED: value };
    assert.equal(isClinicalCalculatorEnabled(env), false, `valor ${value}`);
  }
  assert.equal(isClinicalCalculatorEnabled({ CLINICAL_CALCULATOR_ENABLED: 'true' }), true);
});

test('el endpoint responde 403 si no está habilitada', () => {
  const previous = process.env.CLINICAL_CALCULATOR_ENABLED;
  delete process.env.CLINICAL_CALCULATOR_ENABLED;
  try {
    const controller = new CalculatorController(calculator);
    assert.throws(() => controller.calculate({}, { ...base, currentGlucose: 150 }), ForbiddenException);
  } finally {
    if (previous !== undefined) process.env.CLINICAL_CALCULATOR_ENABLED = previous;
  }
});

test('habilitada explícitamente, el endpoint aplica la protección < 70', () => {
  const previous = process.env.CLINICAL_CALCULATOR_ENABLED;
  process.env.CLINICAL_CALCULATOR_ENABLED = 'true';
  try {
    const controller = new CalculatorController(calculator);
    assert.equal(controller.calculate({}, { ...base, currentGlucose: 65 }).hypoglycemia, true);
    assert.equal(controller.calculate({}, { ...base, currentGlucose: 150 }).hypoglycemia, false);
  } finally {
    if (previous === undefined) delete process.env.CLINICAL_CALCULATOR_ENABLED;
    else process.env.CLINICAL_CALCULATOR_ENABLED = previous;
  }
});

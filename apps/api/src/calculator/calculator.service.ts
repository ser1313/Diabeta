import { Injectable } from '@nestjs/common';
import { CalculateDoseDto } from './calculator.dto';

// Por debajo de este valor (mg/dL) se considera hipoglucemia y no se calcula
// ninguna dosis. Decisión aprobada por el propietario del proyecto.
export const HYPOGLYCEMIA_THRESHOLD_MG_DL = 70;

const DISCLAIMER =
  'Cálculo matemático orientativo. No sustituye las pautas de tu equipo sanitario. No administres insulina basándote únicamente en este resultado.';

@Injectable()
export class CalculatorService {
  calculate(d: CalculateDoseDto) {
    if (d.currentGlucose < HYPOGLYCEMIA_THRESHOLD_MG_DL) {
      return {
        hypoglycemia: true,
        calculatedUnits: 0,
        warning:
          'Glucosa baja: no se aconseja administrar insulina. Sigue la pauta de tu equipo sanitario para tratar la hipoglucemia.',
        informational: true,
        disclaimer: DISCLAIMER,
      };
    }

    const meal = d.carbsGrams / d.insulinToCarbRatio;
    const correction = (d.currentGlucose - d.targetGlucose) / d.correctionFactor;
    const beforeActive = meal + correction;
    const calculatedUnits = Math.max(0, beforeActive - d.activeInsulinUnits);

    return {
      hypoglycemia: false,
      mealComponent: Number(meal.toFixed(2)),
      correctionComponent: Number(correction.toFixed(2)),
      activeInsulinDeduction: Number(d.activeInsulinUnits.toFixed(2)),
      calculatedUnits: Number(calculatedUnits.toFixed(2)),
      informational: true,
      disclaimer: DISCLAIMER,
    };
  }
}

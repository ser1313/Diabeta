import { Injectable } from '@nestjs/common';
import { CalculateDoseDto } from './calculator.dto';

@Injectable()
export class CalculatorService {
  calculate(d: CalculateDoseDto) {
    const meal = d.carbsGrams / d.insulinToCarbRatio;
    const correction = (d.currentGlucose - d.targetGlucose) / d.correctionFactor;
    const beforeActive = meal + correction;
    const calculatedUnits = Math.max(0, beforeActive - d.activeInsulinUnits);

    return {
      mealComponent: Number(meal.toFixed(2)),
      correctionComponent: Number(correction.toFixed(2)),
      activeInsulinDeduction: Number(d.activeInsulinUnits.toFixed(2)),
      calculatedUnits: Number(calculatedUnits.toFixed(2)),
      informational: true,
      disclaimer: 'Cálculo matemático orientativo. No sustituye las pautas de tu equipo sanitario. No administres insulina basándote únicamente en este resultado.',
    };
  }
}

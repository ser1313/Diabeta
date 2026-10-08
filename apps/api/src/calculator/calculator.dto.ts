import { IsNumber, Min } from 'class-validator';

const finite = { allowNaN: false, allowInfinity: false } as const;

export class CalculateDoseDto {
  @IsNumber(finite) @Min(0) carbsGrams!: number;
  @IsNumber(finite) @Min(0.1) insulinToCarbRatio!: number;
  @IsNumber(finite) currentGlucose!: number;
  @IsNumber(finite) targetGlucose!: number;
  @IsNumber(finite) @Min(0.1) correctionFactor!: number;
  @IsNumber(finite) @Min(0) activeInsulinUnits!: number;
}

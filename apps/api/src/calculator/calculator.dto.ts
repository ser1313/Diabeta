import { IsNumber, Max, Min } from 'class-validator';

const finite = { allowNaN: false, allowInfinity: false } as const;

export class CalculateDoseDto {
  @IsNumber(finite) @Min(0) @Max(300) carbsGrams!: number;
  @IsNumber(finite) @Min(0.1) @Max(100) insulinToCarbRatio!: number;
  @IsNumber(finite) @Min(20) @Max(1000) currentGlucose!: number;
  @IsNumber(finite) @Min(20) @Max(1000) targetGlucose!: number;
  @IsNumber(finite) @Min(0.1) @Max(200) correctionFactor!: number;
  @IsNumber(finite) @Min(0) @Max(200) activeInsulinUnits!: number;
}

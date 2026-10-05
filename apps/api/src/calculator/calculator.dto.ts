import { IsNumber, Min } from 'class-validator';

export class CalculateDoseDto {
  @IsNumber() @Min(0) carbsGrams!: number;
  @IsNumber() @Min(0.1) insulinToCarbRatio!: number;
  @IsNumber() currentGlucose!: number;
  @IsNumber() targetGlucose!: number;
  @IsNumber() @Min(0.1) correctionFactor!: number;
  @IsNumber() @Min(0) activeInsulinUnits!: number;
}

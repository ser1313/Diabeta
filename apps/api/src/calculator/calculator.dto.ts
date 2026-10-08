import { IsNumber, Max, Min } from 'class-validator';

export class CalculateDoseDto {
  @IsNumber() @Min(0) @Max(300) carbsGrams!: number;
  @IsNumber() @Min(0.1) @Max(100) insulinToCarbRatio!: number;
  @IsNumber() @Min(20) @Max(1000) currentGlucose!: number;
  @IsNumber() @Min(20) @Max(1000) targetGlucose!: number;
  @IsNumber() @Min(0.1) @Max(200) correctionFactor!: number;
  @IsNumber() @Min(0) @Max(200) activeInsulinUnits!: number;
}

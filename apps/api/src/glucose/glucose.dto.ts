import { IsDateString, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

const finite = { allowNaN: false, allowInfinity: false } as const;

export class CreateGlucoseDto {
  @IsNumber(finite)
  @Min(20)
  @Max(1000)
  value!: number;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  source?: string;

  @IsDateString()
  recordedAt!: string;
}

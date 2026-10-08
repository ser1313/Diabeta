import { IsDateString, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateGlucoseDto {
  @IsNumber()
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

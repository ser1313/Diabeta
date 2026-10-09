import { IsDateString, IsNumber, IsString, Max, MaxLength, Min } from 'class-validator';

const finite = { allowNaN: false, allowInfinity: false } as const;

export class CreateInsulinDto {
  @IsNumber(finite)
  @Min(0)
  @Max(200)
  units!: number;

  @IsString()
  @MaxLength(100)
  insulinType!: string;

  @IsDateString()
  recordedAt!: string;
}

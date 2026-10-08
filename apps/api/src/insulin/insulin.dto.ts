import { IsDateString, IsNumber, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateInsulinDto {
  @IsNumber()
  @Min(0)
  @Max(200)
  units!: number;

  @IsString()
  @MaxLength(100)
  insulinType!: string;

  @IsDateString()
  recordedAt!: string;
}

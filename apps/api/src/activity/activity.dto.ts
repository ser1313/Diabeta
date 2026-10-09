import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

const finite = { allowNaN: false, allowInfinity: false } as const;

export class CreateActivityDto {
  @IsString()
  @MaxLength(100)
  type!: string;

  @IsNumber(finite)
  @Min(1)
  @Max(1440)
  minutes!: number;

  @IsOptional()
  @IsNumber(finite)
  @Min(0)
  @Max(100000)
  calories?: number;
}

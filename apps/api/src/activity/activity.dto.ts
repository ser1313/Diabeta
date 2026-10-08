import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateActivityDto {
  @IsString()
  @MaxLength(100)
  type!: string;

  @IsNumber()
  @Min(1)
  @Max(1440)
  minutes!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100000)
  calories?: number;
}

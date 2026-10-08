import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateMealDto {
  @IsString()
  @MaxLength(200)
  name!: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1000)
  carbs?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(10000)
  calories?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(500)
  protein?: number;

  @IsOptional()
  @IsString()
  @MaxLength(2048)
  photoUrl?: string;
}

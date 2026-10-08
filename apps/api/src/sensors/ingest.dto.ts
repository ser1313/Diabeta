import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsDateString, IsNumber, Max, Min, ValidateNested } from 'class-validator';

export class SensorGlucoseReadingDto {
  @IsNumber()
  @Min(20)
  @Max(1000)
  value!: number;

  @IsDateString()
  recordedAt!: string;
}

export class IngestSensorDto {
  @IsArray()
  @ArrayMaxSize(1000)
  @ValidateNested({ each: true })
  @Type(() => SensorGlucoseReadingDto)
  readings!: SensorGlucoseReadingDto[];
}

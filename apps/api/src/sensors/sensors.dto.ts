import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export enum SensorProvider {
  FREESTYLE_LIBRE = 'freestyle_libre',
  DEXCOM = 'dexcom',
}

export class ConnectSensorDto {
  @IsEnum(SensorProvider)
  provider!: SensorProvider;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  externalId?: string;
}

export class SensorReadingDto {
  @IsNumber({ allowNaN: false, allowInfinity: false })
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
  @Type(() => SensorReadingDto)
  readings!: SensorReadingDto[];
}

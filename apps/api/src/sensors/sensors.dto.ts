import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  NotContains,
  ValidateIf,
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

  @ValidateIf((_, value) => value !== undefined)
  @IsString()
  @MaxLength(200)
  @Matches(/\S/u)
  @NotContains('\0')
  externalReadingId?: string;
}

export class IngestSensorDto {
  @IsArray()
  @ArrayMaxSize(1000)
  @ValidateNested({ each: true })
  @Type(() => SensorReadingDto)
  readings!: SensorReadingDto[];
}

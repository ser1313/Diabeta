import{Type}from'class-transformer';import{ArrayMaxSize,IsArray,IsDateString,IsNumber,ValidateNested}from'class-validator';
const finite={allowNaN:false,allowInfinity:false}as const;
export class SensorGlucoseReadingDto{@IsNumber(finite) value!:number;@IsDateString() recordedAt!:string}
export class IngestSensorDto{@IsArray()@ArrayMaxSize(1000)@ValidateNested({each:true})@Type(()=>SensorGlucoseReadingDto)readings!:SensorGlucoseReadingDto[]}
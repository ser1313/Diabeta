import{BadRequestException,Injectable}from'@nestjs/common';import{PrismaService}from'../prisma.service';import{ConnectSensorDto}from'./sensors.dto';

const SUPPORTED_PROVIDERS=['freestyle_libre','dexcom'] as const;
type SupportedProvider=typeof SUPPORTED_PROVIDERS[number];

@Injectable()
export class SensorsService{
  constructor(private p:PrismaService){}
  list(userId:string){
    return this.p.sensorConnection.findMany({
      where:{userId},
      select:{id:true,provider:true,externalId:true,status:true,lastSyncAt:true,createdAt:true}
    });
  }
  connect(userId:string,d:ConnectSensorDto){
    return this.p.sensorConnection.upsert({
      where:{userId_provider:{userId,provider:d.provider}},
      create:{userId,provider:d.provider,externalId:d.externalId,status:'pending'},
      update:{externalId:d.externalId,status:'pending'}
    });
  }
  async ingest(userId:string,provider:string,readings:Array<{value:number;recordedAt:string}>){
    if(!SUPPORTED_PROVIDERS.includes(provider as SupportedProvider)){
      throw new BadRequestException('Proveedor de sensor no compatible');
    }
    const connection=await this.p.sensorConnection.findUnique({
      where:{userId_provider:{userId,provider}}
    });
    if(!connection){
      throw new BadRequestException('El sensor no está conectado');
    }
    const data=readings.map(x=>({
      userId,
      value:x.value,
      source:provider,
      recordedAt:new Date(x.recordedAt)
    }));
    if(data.length)await this.p.glucoseReading.createMany({data});
    await this.p.sensorConnection.update({
      where:{userId_provider:{userId,provider}},
      data:{status:'connected',lastSyncAt:new Date()}
    });
    return{imported:data.length,provider};
  }
}

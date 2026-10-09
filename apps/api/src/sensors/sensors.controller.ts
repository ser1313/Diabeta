import { Body, Controller, Get, Param, ParseEnumPipe, Post, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { SensorsService } from './sensors.service';
import { ConnectSensorDto, IngestSensorDto, SensorProvider } from './sensors.dto';

@Controller('sensors')
@UseGuards(JwtGuard)
export class SensorsController {
  constructor(private s: SensorsService) {}

  @Get()
  list(@Req() r: any) {
    return this.s.list(r.user.sub);
  }

  @Post('connect')
  connect(@Req() r: any, @Body() d: ConnectSensorDto) {
    return this.s.connect(r.user.sub, d);
  }

  @Post(':provider/ingest')
  ingest(
    @Req() r: any,
    @Param('provider', new ParseEnumPipe(SensorProvider)) provider: SensorProvider,
    @Body() d: IngestSensorDto,
  ) {
    return this.s.ingest(r.user.sub, provider, d.readings);
  }
}

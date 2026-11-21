import { Body, Controller, Get, Post, Query, Req, StreamableFile, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { CreateGlucoseDto } from './glucose.dto';
import { GlucoseService } from './glucose.service';

type AuthenticatedRequest = { user: { sub: string } };

@Controller('glucose')
@UseGuards(JwtGuard)
export class GlucoseController {
  constructor(private readonly glucose: GlucoseService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest) {
    return this.glucose.list(request.user.sub);
  }

  @Get('export.csv')
  async exportCsv(
    @Req() request: AuthenticatedRequest,
    @Query('from') from: unknown,
    @Query('to') to: unknown,
  ) {
    const csv = await this.glucose.exportCsv(request.user.sub, from, to);
    return new StreamableFile(Buffer.from(csv, 'utf8'), {
      type: 'text/csv; charset=utf-8',
      disposition: 'attachment; filename="diabeta-glucose.csv"',
    });
  }

  @Post()
  create(@Req() request: AuthenticatedRequest, @Body() dto: CreateGlucoseDto) {
    return this.glucose.create(request.user.sub, dto);
  }
}

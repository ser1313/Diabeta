import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateGlucoseDto } from './glucose.dto';

const MAX_FUTURE_SKEW_MS = 10 * 60 * 1000;

@Injectable()
export class GlucoseService {
  constructor(private p: PrismaService) {}

  create(userId: string, d: CreateGlucoseDto) {
    const recordedAt = new Date(d.recordedAt);
    if (recordedAt.getTime() > Date.now() + MAX_FUTURE_SKEW_MS) {
      throw new BadRequestException('La fecha de la lectura no puede estar más de 10 minutos en el futuro.');
    }
    return this.p.glucoseReading.create({
      data: { userId, value: d.value, source: d.source || 'manual', recordedAt },
    });
  }

  list(userId: string) {
    return this.p.glucoseReading.findMany({ where: { userId }, orderBy: { recordedAt: 'desc' }, take: 100 });
  }
}

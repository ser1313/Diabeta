import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateInsulinDto } from './insulin.dto';

const MAX_FUTURE_SKEW_MS = 10 * 60 * 1000;

@Injectable()
export class InsulinService {
  constructor(private p: PrismaService) {}

  create(userId: string, d: CreateInsulinDto) {
    const recordedAt = new Date(d.recordedAt);
    if (recordedAt.getTime() > Date.now() + MAX_FUTURE_SKEW_MS) {
      throw new BadRequestException('La fecha de la administración no puede estar más de 10 minutos en el futuro.');
    }
    return this.p.insulinEntry.create({
      data: { userId, units: d.units, insulinType: d.insulinType, recordedAt },
    });
  }

  list(userId: string) {
    return this.p.insulinEntry.findMany({ where: { userId }, orderBy: { recordedAt: 'desc' }, take: 100 });
  }
}

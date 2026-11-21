import { BadRequestException, ConflictException, Injectable, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateGlucoseDto } from './glucose.dto';

const MAX_FUTURE_SKEW_MS = 10 * 60 * 1000;
const omitInternalIds = { clientRequestId: true, externalReadingId: true } as const;

@Injectable()
export class GlucoseService {
  constructor(private p: PrismaService) {}

  async create(userId: string, d: CreateGlucoseDto) {
    const recordedAt = new Date(d.recordedAt);
    if (recordedAt.getTime() > Date.now() + MAX_FUTURE_SKEW_MS) {
      throw new BadRequestException('La fecha de la lectura no puede estar más de 10 minutos en el futuro.');
    }
    const clientRequestId = d.clientRequestId?.toLowerCase();
    const data = { userId, value: d.value, source: d.source || 'manual', recordedAt, clientRequestId };

    if (!clientRequestId) {
      return this.p.glucoseReading.create({ data, omit: omitInternalIds });
    }

    const [inserted] = await this.p.glucoseReading.createManyAndReturn({
      data, skipDuplicates: true, omit: omitInternalIds,
    });
    if (inserted) return inserted;

    const existing = await this.p.glucoseReading.findUnique({
      where: { userId_clientRequestId: { userId, clientRequestId } },
      omit: omitInternalIds,
    });
    if (!existing) throw new InternalServerErrorException('No se pudo guardar la lectura de glucosa.');
    if (existing.value !== data.value || existing.source !== data.source ||
        existing.recordedAt.getTime() !== recordedAt.getTime()) {
      throw new ConflictException('Este identificador ya se utilizó para una lectura distinta.');
    }
    return existing;
  }

  list(userId: string) {
    return this.p.glucoseReading.findMany({ where: { userId }, orderBy: { recordedAt: 'desc' }, take: 100, omit: omitInternalIds });
  }
}

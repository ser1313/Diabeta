import { BadRequestException, Injectable, UnprocessableEntityException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateGlucoseDto } from './glucose.dto';

const MAX_FUTURE_SKEW_MS = 10 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_EXPORT_DAYS = 90;
const MAX_EXPORT_ROWS = 10_000;

function parseExportDate(value: unknown): Date {
  if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
    const date = new Date(value);
    if (Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value) {
      return date;
    }
  }
  throw new BadRequestException('Indica fechas válidas en from y to con el formato AAAA-MM-DD.');
}

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

  async exportCsv(userId: string, from: unknown, to: unknown): Promise<string> {
    const start = parseExportDate(from);
    const end = parseExportDate(to);
    const endExclusive = new Date(end.getTime() + DAY_MS);
    if (start > end || endExclusive.getTime() - start.getTime() > MAX_EXPORT_DAYS * DAY_MS) {
      throw new BadRequestException('El intervalo de exportación debe estar ordenado y abarcar entre 1 y 90 días.');
    }

    const readings = await this.p.glucoseReading.findMany({
      where: { userId, recordedAt: { gte: start, lt: endExclusive } },
      orderBy: [{ recordedAt: 'asc' }, { id: 'asc' }],
      select: { recordedAt: true, value: true, unit: true },
      take: MAX_EXPORT_ROWS + 1,
    });
    if (readings.length > MAX_EXPORT_ROWS) {
      throw new UnprocessableEntityException('El intervalo supera las 10.000 lecturas. Selecciona menos días.');
    }

    const rows = ['recordedAt,value,unit'];
    for (const { recordedAt, value, unit } of readings) {
      // Solo exportar etiquetas de unidad conocidas, sin texto arbitrario.
      const csvUnit = unit === 'mg/dL' || unit === 'mmol/L' ? unit : '';
      rows.push(`${recordedAt.toISOString()},${value},${csvUnit}`);
    }
    return rows.join('\r\n') + '\r\n';
  }
}

import { BadRequestException, ConflictException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { ConnectSensorDto, SensorProvider, SensorReadingDto } from './sensors.dto';

@Injectable()
export class SensorsService {
  constructor(private p: PrismaService) {}

  list(userId: string) {
    return this.p.sensorConnection.findMany({
      where: { userId },
      select: { id: true, provider: true, externalId: true, status: true, lastSyncAt: true, createdAt: true },
    });
  }

  connect(userId: string, d: ConnectSensorDto) {
    return this.p.sensorConnection.upsert({
      where: { userId_provider: { userId, provider: d.provider } },
      create: { userId, provider: d.provider, externalId: d.externalId, status: 'pending' },
      update: { externalId: d.externalId, status: 'pending' },
    });
  }

  async ingest(userId: string, provider: SensorProvider, readings: SensorReadingDto[]) {
    const now = Date.now();
    const data = readings.map((reading) => {
      const recordedAt = new Date(reading.recordedAt);
      if (!Number.isFinite(recordedAt.getTime())) {
        throw new BadRequestException('Sensor reading timestamp must be a valid date');
      }
      if (recordedAt.getTime() > now + 10 * 60 * 1000) {
        throw new BadRequestException('Sensor reading timestamp cannot be more than 10 minutes in the future');
      }
      if (!Number.isFinite(reading.value) || reading.value < 20 || reading.value > 1000) {
        throw new BadRequestException('Sensor glucose value must be between 20 and 1000');
      }
      return { userId, value: reading.value, source: provider, recordedAt, externalReadingId: reading.externalReadingId };
    });

    // Consistent key order avoids lock-order inversions between overlapping batches.
    data.sort((a, b) => {
      const left = a.externalReadingId ?? '';
      const right = b.externalReadingId ?? '';
      return left < right ? -1 : left > right ? 1 : 0;
    });

    return this.p.$transaction(async (tx) => {
      const where = { userId_provider: { userId, provider } };
      const connection = await tx.sensorConnection.findUnique({ where, select: { id: true } });
      if (!connection) {
        throw new BadRequestException('Connect this sensor before importing readings');
      }
      if (!data.length) return { imported: 0, provider };

      const { count } = await tx.glucoseReading.createMany({ data, skipDuplicates: true });
      if (count < data.length) {
        const externalIds = data.flatMap((reading) => reading.externalReadingId ? [reading.externalReadingId] : []);
        const saved = await tx.glucoseReading.findMany({
          where: { userId, source: provider, externalReadingId: { in: externalIds } },
          select: { externalReadingId: true, value: true, recordedAt: true },
        });
        const byId = new Map(saved.map((reading) => [reading.externalReadingId, reading]));
        for (const reading of data) {
          if (!reading.externalReadingId) continue;
          const previous = byId.get(reading.externalReadingId);
          if (!previous || previous.value !== reading.value ||
              previous.recordedAt.getTime() !== reading.recordedAt.getTime()) {
            throw new ConflictException('Este identificador de sensor ya se utilizó para una lectura distinta.');
          }
        }
      }

      if (count > 0) {
        await tx.sensorConnection.update({
          where: { id: connection.id },
          data: { status: 'connected', lastSyncAt: new Date() },
        });
      }
      return { imported: count, provider };
    });
  }
}

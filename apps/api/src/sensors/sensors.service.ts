import { BadRequestException, Injectable } from '@nestjs/common';
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
    const connection = await this.p.sensorConnection.findUnique({
      where: { userId_provider: { userId, provider } },
      select: { id: true },
    });
    if (!connection) {
      throw new BadRequestException('Connect this sensor before importing readings');
    }

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
      return { userId, value: reading.value, source: provider, recordedAt };
    });

    if (data.length) await this.p.glucoseReading.createMany({ data });
    await this.p.sensorConnection.update({
      where: { userId_provider: { userId, provider } },
      data: { status: 'connected', lastSyncAt: new Date() },
    });
    return { imported: data.length, provider };
  }
}

import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { UpdateSettingsDto } from './settings.dto';

@Injectable()
export class SettingsService {
  constructor(private p: PrismaService) {}

  get(userId: string) {
    return this.p.alertSettings.upsert({ where: { userId }, create: { userId }, update: {} });
  }

  async update(userId: string, d: UpdateSettingsDto) {
    const current = await this.get(userId);
    const low = d.lowThreshold ?? current.lowThreshold;
    const high = d.highThreshold ?? current.highThreshold;

    if (low >= high) {
      throw new BadRequestException('El umbral bajo debe ser inferior al umbral alto.');
    }

    return this.p.alertSettings.upsert({
      where: { userId },
      create: { userId, ...d },
      update: d,
    });
  }
}

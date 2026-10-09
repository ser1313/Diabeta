import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class ProfileService {
  constructor(private p: PrismaService) {}

  async get(userId: string) {
    const u = await this.p.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, firstName: true, language: true, createdAt: true },
    });
    if (!u) throw new NotFoundException();
    return u;
  }

  async update(userId: string, data: { firstName?: string; language?: string }) {
    const normalized = {
      ...data,
      ...(data.firstName !== undefined ? { firstName: data.firstName.trim() } : {}),
      ...(data.language !== undefined ? { language: data.language.trim().toLowerCase() } : {}),
    };
    if (normalized.firstName !== undefined && !normalized.firstName) {
      throw new BadRequestException('First name is required.');
    }
    return this.p.user.update({
      where: { id: userId },
      data: normalized,
      select: { id: true, email: true, firstName: true, language: true },
    });
  }
}

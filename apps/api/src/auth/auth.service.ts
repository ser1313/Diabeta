import { BadRequestException, ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma.service';
import { LoginDto, RegisterDto } from './auth.dto';

@Injectable()
export class AuthService {
  constructor(private p: PrismaService, private jwt: JwtService) {}

  async register(d: RegisterDto) {
    const email = d.email.trim().toLowerCase();
    const firstName = d.firstName.trim();
    if (!firstName) throw new BadRequestException('First name cannot be empty');
    if (await this.p.user.findUnique({ where: { email } })) {
      throw new ConflictException('Email already registered');
    }
    const u = await this.p.user.create({
      data: { email, passwordHash: await argon2.hash(d.password), firstName },
    });
    return this.issue(u.id, u.email);
  }

  async login(d: LoginDto) {
    const email = d.email.trim().toLowerCase();
    const u = await this.p.user.findUnique({ where: { email } });
    if (!u || !(await argon2.verify(u.passwordHash, d.password))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.issue(u.id, u.email);
  }

  private issue(id: string, email: string) {
    return { accessToken: this.jwt.sign({ sub: id, email }), user: { id, email } };
  }
}

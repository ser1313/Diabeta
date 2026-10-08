import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { PrismaService } from '../prisma.service';

@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const isProduction = config.get<string>('NODE_ENV') === 'production';
        const secret = config.get<string>('JWT_SECRET')?.trim();

        if (isProduction && (!secret || secret.length < 32)) {
          throw new Error('JWT_SECRET must be configured with at least 32 characters in production');
        }

        return {
          secret: secret || 'change-me-local-only',
          signOptions: { expiresIn: '12h' },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, PrismaService],
  exports: [AuthService],
})
export class AuthModule {}

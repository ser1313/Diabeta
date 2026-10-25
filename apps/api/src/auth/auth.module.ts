import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { PrismaService } from '../prisma.service';

@Module({
  imports: [
    // Única configuración JWT de la API: global para que todos los módulos
    // verifiquen los tokens con el mismo secreto con el que se firman.
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const secret = config.get<string>('JWT_SECRET');
        const production = config.get<string>('NODE_ENV') === 'production';
        if (production && (!secret || secret.length < 32)) {
          throw new Error('JWT_SECRET must contain at least 32 characters in production');
        }
        return {
          secret: secret || 'change-me-local-only',
          signOptions: { expiresIn: '12h', algorithm: 'HS256' },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, PrismaService],
  exports: [AuthService],
})
export class AuthModule {}

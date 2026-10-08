import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  const configuredOrigins = process.env.CORS_ORIGIN?.split(',').map((x) => x.trim()).filter(Boolean);
  if (process.env.NODE_ENV === 'production' && !configuredOrigins?.length) {
    throw new Error('CORS_ORIGIN must be configured in production');
  }
  app.enableCors({
    origin: configuredOrigins?.length ? configuredOrigins : true,
    credentials: false,
  });
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: true,
  }));
  await app.listen(process.env.PORT || 3000);
}
bootstrap();

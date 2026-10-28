// Comprueba que la API arranca y que todos los módulos verifican los tokens
// JWT con el mismo secreto con el que AuthService los firma.
const assert = require('node:assert/strict');
const test = require('node:test');
require('reflect-metadata');

// Sin secreto al importar: reproduce el arranque local, donde ConfigModule
// carga el .env después de que se evalúen los decoradores de los módulos.
delete process.env.JWT_SECRET;
delete process.env.NODE_ENV;

const { NestFactory } = require('@nestjs/core');
const { UnauthorizedException } = require('@nestjs/common');
const { PrismaService } = require('../dist/prisma.service.js');

// Sin base de datos en las pruebas: se evita la conexión real.
PrismaService.prototype.onModuleInit = async () => {};
PrismaService.prototype.onModuleDestroy = async () => {};

const { AppModule } = require('../dist/app.module.js');
const { AuthService } = require('../dist/auth/auth.service.js');
const { JwtGuard } = require('../dist/auth/jwt.guard.js');

const protectedModules = [
  ['GlucoseModule', '../dist/glucose/glucose.module.js'],
  ['InsulinModule', '../dist/insulin/insulin.module.js'],
  ['MetricsModule', '../dist/metrics/metrics.module.js'],
  ['GuardianModule', '../dist/guardian/guardian.module.js'],
  ['SettingsModule', '../dist/settings/settings.module.js'],
  ['MedicalModule', '../dist/medical/medical.module.js'],
  ['ProfileModule', '../dist/profile/profile.module.js'],
  ['NutritionModule', '../dist/nutrition/nutrition.module.js'],
  ['ActivityModule', '../dist/activity/activity.module.js'],
  ['SensorsModule', '../dist/sensors/sensors.module.js'],
];

function contextWithToken(token) {
  const req = { headers: { authorization: `Bearer ${token}` } };
  return { req, ctx: { switchToHttp: () => ({ getRequest: () => req }) } };
}

async function createContext() {
  return NestFactory.createApplicationContext(AppModule, {
    logger: false,
    abortOnError: false,
  });
}

async function assertTokensAcceptedEverywhere(app) {
  const token = app.get(AuthService).issue('user-test-1', 'test@example.com').accessToken;
  for (const [name, path] of protectedModules) {
    const guard = app.select(require(path)[name]).get(JwtGuard);
    const { req, ctx } = contextWithToken(token);
    assert.equal(guard.canActivate(ctx), true, `${name} rechaza un token válido`);
    assert.equal(req.user.sub, 'user-test-1');
  }
}

test('la aplicación arranca y resuelve todas sus dependencias', async () => {
  const app = await createContext();
  await app.close();
});

test('sin JWT_SECRET en desarrollo, los módulos aceptan los tokens de AuthService', async () => {
  delete process.env.JWT_SECRET;
  const app = await createContext();
  try {
    await assertTokensAcceptedEverywhere(app);
  } finally {
    await app.close();
  }
});

test('con JWT_SECRET cargado tras importar (como hace el .env), los tokens siguen siendo válidos', async () => {
  process.env.JWT_SECRET = 'secreto-de-prueba-cargado-desde-env-0123456789';
  const app = await createContext();
  try {
    await assertTokensAcceptedEverywhere(app);
  } finally {
    await app.close();
    delete process.env.JWT_SECRET;
  }
});

test('un token firmado con otro secreto se rechaza', async () => {
  process.env.JWT_SECRET = 'secreto-de-prueba-cargado-desde-env-0123456789';
  const app = await createContext();
  try {
    const { JwtService } = require('@nestjs/jwt');
    const forged = new JwtService({ secret: 'change-me' }).sign({ sub: 'intruso' });
    const guard = app.select(require('../dist/glucose/glucose.module.js').GlucoseModule).get(JwtGuard);
    assert.throws(() => guard.canActivate(contextWithToken(forged).ctx), UnauthorizedException);
  } finally {
    await app.close();
    delete process.env.JWT_SECRET;
  }
});

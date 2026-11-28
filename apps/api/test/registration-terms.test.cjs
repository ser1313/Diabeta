const assert = require('node:assert/strict');
const test = require('node:test');
require('reflect-metadata');
const { BadRequestException, ValidationPipe } = require('@nestjs/common');
const { RegisterDto, REGISTRATION_TERMS_VERSION } = require('../dist/auth/auth.dto.js');
const { AuthService } = require('../dist/auth/auth.service.js');

const registration = {
  email: 'test@example.com',
  password: 'test-password',
  firstName: 'Prueba',
};

test('registro rechaza una aceptación ausente, inválida u obsoleta', async () => {
  const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true });
  const metadata = { type: 'body', metatype: RegisterDto };
  const service = new AuthService();
  for (const input of [
    registration,
    { ...registration, acceptedTermsVersion: true },
    { ...registration, acceptedTermsVersion: 'obsolete' },
  ]) {
    await assert.rejects(pipe.transform(input, metadata), BadRequestException);
    await assert.rejects(service.register(input), BadRequestException);
  }
});

test('registro guarda la versión vigente y fecha del servidor al crear la cuenta', async () => {
  const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true });
  const input = await pipe.transform(
    { ...registration, acceptedTermsVersion: REGISTRATION_TERMS_VERSION },
    { type: 'body', metatype: RegisterDto },
  );
  let saved;
  const service = new AuthService({
    user: {
      findUnique: async () => null,
      create: async ({ data }) => {
        saved = data;
        return { id: 'test-user', email: data.email };
      },
    },
  }, { sign: () => 'test-token' });

  const startedAt = Date.now();
  await service.register(input);

  assert.equal(saved.acceptedTermsVersion, REGISTRATION_TERMS_VERSION);
  assert.ok(saved.termsAcceptedAt instanceof Date);
  assert.ok(saved.termsAcceptedAt.getTime() >= startedAt);
  assert.ok(saved.termsAcceptedAt.getTime() <= Date.now());
});

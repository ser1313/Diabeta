import { defineConfig } from 'prisma/config';

// Prisma 7: la URL de conexión para Migrate ya no va en schema.prisma.
// Con prisma.config.ts no se carga .env automáticamente: DATABASE_URL debe
// existir en el entorno (Docker/CI) o cargarse antes (p. ej. `--env-file`).
// `prisma generate` no necesita conexión, por eso no se exige aquí.
export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: { path: 'prisma/migrations' },
  datasource: { url: process.env.DATABASE_URL ?? '' },
});

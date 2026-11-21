# Diabeta

Aplicación móvil y API para registro y seguimiento de diabetes. **Es una herramienta de apoyo informativo y no sustituye al equipo sanitario ni calcula/modifica dosis de insulina automáticamente.**

## Arquitectura
- Flutter: aplicación móvil.
- NestJS + TypeScript: API.
- Prisma + PostgreSQL: persistencia.
- Docker Compose: entorno reproducible.
- GitHub Actions: validación automática.

## Módulos implementados
- Registro e inicio de sesión con JWT y Argon2.
- Perfil de usuario.
- Glucosa e insulina.
- Métricas TIR y estimación orientativa de HbA1c.
- AI Guardian informativo con umbrales configurables.
- Nutrición, comidas y actividad.
- Catálogo de referencia de insulinas rápidas en España; debe verificarse siempre la ficha técnica vigente.
- Perfil médico y tarjeta QR privada.
- SOS con llamada al 112 desde el dispositivo.
- Capa de adaptación para sensores FreeStyle Libre y Dexcom.

## Sensores
La API dispone de una capa sensors para registrar proveedor, identificador externo, estado y sincronización. La conexión directa con servicios propietarios requiere credenciales, API o SDK autorizados por cada fabricante; el proyecto no simula ni inventa dichas credenciales.

## Exportar lecturas de glucosa

`GET /glucose/export.csv?from=2026-11-01&to=2026-11-21` devuelve las lecturas de la cuenta autenticada mediante `Authorization: Bearer <token>`. Las dos fechas son inclusivas y se interpretan en UTC. El CSV contiene las columnas `recordedAt`, `value` y `unit`, con las lecturas ordenadas de menor a mayor fecha.

El intervalo admite hasta 90 días. Si contiene más de 10.000 lecturas, la API responde con un error 422 para que puedas elegir un intervalo más corto.

## Arranque local
1. Copiar apps/api/.env.example a .env y establecer un JWT_SECRET aleatorio.
2. Ejecutar docker compose up --build.
3. La API queda en http://localhost:3000.
4. Para Flutter Android emulador usar la URL por defecto; para dispositivo físico compilar con --dart-define=API_URL=http://IP_DEL_SERVIDOR:3000.

## Seguridad
- No guardar secretos reales en Git.
- Docker Compose no arranca sin JWT_SECRET definido en el archivo .env.
- En producción: NODE_ENV=production, JWT_SECRET de al menos 32 caracteres y CORS_ORIGIN con los orígenes permitidos; la API se niega a arrancar si falta alguno.
- HTTPS obligatorio en producción.
- La tarjeta QR solo expone los campos médicos configurados.
- Los avisos de Guardian son orientativos y no realizan recomendaciones de dosis.

## Estado
MVP core en desarrollo activo sobre la arquitectura congelada v2.7. Los siguientes bloques son endurecimiento, pruebas, UX y conexiones externas autorizadas.

## Retomar el trabajo
Estado, decisiones y procedimientos: `docs/ESTADO.md`.

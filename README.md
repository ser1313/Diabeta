# Diabeta

Aplicación móvil y API para registro y seguimiento de diabetes. **Es una herramienta de apoyo informativo y no sustituye al equipo sanitario. No modifica dosis de insulina automáticamente.**

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
- Calculadora de bolo opcional e informativa: usa solo los parámetros que introduce la persona usuaria y no calcula ninguna dosis si la glucosa es inferior a 70 mg/dL (muestra un aviso en rojo).
- Perfil médico y tarjeta QR privada.
- SOS con llamada al 112 desde el dispositivo.
- Capa de adaptación para sensores FreeStyle Libre y Dexcom.

## Sensores
La API dispone de una capa sensors para registrar proveedor, identificador externo, estado y sincronización. La conexión directa con servicios propietarios requiere credenciales, API o SDK autorizados por cada fabricante; el proyecto no simula ni inventa dichas credenciales.

## Arranque local
1. Copiar apps/api/.env.example a .env y establecer un JWT_SECRET aleatorio.
2. Ejecutar docker compose up --build.
3. La API queda en http://localhost:3000.
4. Para Flutter Android emulador usar la URL por defecto; para dispositivo físico compilar con --dart-define=API_URL=http://IP_DEL_SERVIDOR:3000.

## Seguridad
- No guardar secretos reales en Git.
- Cambiar el JWT secret de Docker antes de producción.
- HTTPS obligatorio en producción.
- La tarjeta QR solo expone los campos médicos configurados.
- Los avisos de Guardian son orientativos y no realizan recomendaciones de dosis.

## Estado
MVP core en desarrollo activo sobre la arquitectura congelada v2.7. Los siguientes bloques son endurecimiento, pruebas, UX y conexiones externas autorizadas.

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

## Arranque local
1. Copiar apps/api/.env.example a .env y establecer un JWT_SECRET aleatorio.
2. Ejecutar docker compose up --build.
3. La API queda en http://localhost:3000.
4. Para Flutter Android emulador usar la URL por defecto; para dispositivo físico compilar con --dart-define=API_URL=http://IP_DEL_SERVIDOR:3000.

## Web de pruebas

Arranca la API local y ejecuta:

```sh
cd apps/mobile
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define=API_URL=http://127.0.0.1:3000
```

Abre `http://127.0.0.1:8080`. Si la API restringe CORS, añade ese origen exacto a `CORS_ORIGIN`.

Para comprobar una compilación release, usa una API HTTPS de pruebas con acceso restringido:

```sh
flutter build web --release --no-web-resources-cdn --pwa-strategy=none --dart-define=API_URL=https://api.example.invalid
```

Sustituye el dominio de ejemplo por el de tu API. Sirve `build/web` por HTTPS, permite el origen web exacto en el CORS de la API y usa datos ficticios. La URL de la API forma parte del JavaScript compilado. La calculadora clínica debe quedar deshabilitada en la app y en la API antes de distribuir esta compilación.

El arranque web exige un contexto seguro, incluido localhost para desarrollo. CanvasKit y Roboto se sirven desde el mismo origen. La fuente es la copia Roboto Regular del SDK de Flutter 3.29, empaquetada como WOFF2 con su licencia.

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

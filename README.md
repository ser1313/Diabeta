# DIABETA

Aplicación móvil de seguimiento personal de la diabetes: registro de glucosa, insulina, comidas y ejercicio; dashboard, perfil de emergencia, alertas e información de apoyo. **No es un dispositivo médico, no diagnostica y no sustituye la pauta del profesional sanitario.**

## Arquitectura

- `apps/mobile`: cliente Expo/React Native, preparado para Android, iOS y web; interfaz bilingüe ES/EN y modo claro/oscuro del sistema.
- `apps/api`: REST API Fastify/TypeScript con JWT, validación Zod, OpenAPI (`/docs`) y servicios clínicamente seguros.
- PostgreSQL 16 mediante Docker y migración SQL inicial en `apps/api/migrations`.
- CI GitHub Actions: lint, typecheck, tests y build.

El API incluye endpoints de registro/inicio/recovery, perfil y consentimiento, dashboard, registros de glucosa/insulina/comidas/ejercicio, contactos de emergencia, calculadora matemática de apoyo, AI Guardian, adaptadores de sensores y QR de emergencia. Todas las rutas salvo autenticación y health check exigen Bearer JWT. La validación de DTOs limita tipos, tamaños y rangos básicos.

## Inicio local

```bash
cp .env.example .env
# Sustituye JWT_SECRET por una cadena aleatoria segura de >=32 caracteres
npm install
docker compose up -d postgres
npm run dev:api
npm run dev:mobile
```

El API queda en `http://localhost:3000`, salud en `/health` y OpenAPI en `/docs`. Para ejecutar la app, abre el QR mostrado por Expo o usa `npm run android` / `npm run ios` con los SDKs correspondientes. La vista inicial permite comprobar el flujo de registro rápido sin backend; la siguiente fase conecta su cliente HTTP autenticado con la API.

## Calidad

```bash
npm run lint
npm run typecheck
npm test
npm run build
```

## Seguridad y privacidad

No hay secretos en el repositorio: utiliza `.env` local y un gestor de secretos en producción. TLS, rotación/revocación de tokens, limitación de tasa, correo transaccional, cifrado en reposo, copias de seguridad, monitorización y una revisión legal/GDPR son requisitos de despliegue antes de tratar datos reales. Los logs no deben incluir datos sanitarios. La recuperación de contraseña expone una respuesta no enumeradora; requiere proveedor de email para entrega real.

## Sensores, visión y notificaciones

La API expone una capa de adaptadores para FreeStyle Libre 2/3 y Dexcom ONE+/G7 sin fingir acceso. Para activarlos se requieren contratos, SDK/API oficial, OAuth/credenciales y consentimiento del usuario de Abbott/Dexcom. El análisis de fotos de comidas y push notifications siguen el mismo patrón: se conectan tras configurar un proveedor de visión y FCM/APNs/Expo respectivamente; nunca se incluyen credenciales de terceros.

## Datos y catálogo

El esquema contiene usuarios, perfiles/configuración, lecturas, insulina, comidas, ejercicio, alertas, contactos, sensores y auditoría. Las marcas de insulina deben administrarse como catálogo configurable por país/fuente clínica, no como lista médica fija. Las migraciones se ejecutan automáticamente al inicializar el volumen PostgreSQL en desarrollo; en producción aplícalas desde un job controlado.

## Limitaciones y siguiente fase

La API usa PostgreSQL automáticamente cuando `DATABASE_URL` está configurada; el repositorio en memoria solo se selecciona de forma explícita con `USE_MEMORY_STORE=true` (útil para tests y previews). Añadir pantallas móviles autenticadas, historial/gráficas, almacenamiento seguro de token (`expo-secure-store`), CRUD de alimentos/catálogo administrable, rate limiting, correo, pruebas E2E y las integraciones oficiales. Los cálculos solo separan aritmética configurable de una recomendación clínica y presentan advertencias explícitas.

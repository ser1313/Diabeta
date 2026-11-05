# Integración Flutter + NestJS para probar DIABETA en Android físico

Esta guía mantiene una única aplicación: Flutter consume la API NestJS y la API persiste en PostgreSQL. No incluye integración con relojes.

## 1. Levantar API y PostgreSQL

Desde la raíz del repositorio:

```bash
cp apps/api/.env.example apps/api/.env
```

Configura un `JWT_SECRET` aleatorio y una contraseña local de PostgreSQL. Después:

```bash
docker compose up --build -d
docker compose ps
curl http://localhost:3000/health
```

La respuesta de salud esperada contiene `{"status":"ok","service":"diabeta-api"}`.

## 2. Conectar el Samsung a la API

El móvil físico no puede usar `10.0.2.2` (esa dirección es para el emulador Android). Conecta el Samsung y el ordenador a la misma red Wi-Fi y averigua la IP LAN del ordenador.

Comprueba desde el ordenador que la API responde en el puerto 3000. Después compila:

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_URL=http://IP_LAN_DEL_ORDENADOR:3000
```

Instala el APK en el Samsung:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Sustituye `IP_LAN_DEL_ORDENADOR` por la IP real del ordenador. No uses esta configuración HTTP en producción: producción exige HTTPS.

## 3. Flujo integrado que se valida

1. Flutter abre registro/inicio de sesión.
2. NestJS valida los datos y devuelve un JWT.
3. Flutter guarda el JWT en almacenamiento seguro.
4. Las peticiones protegidas envían `Authorization: Bearer <token>`.
5. NestJS obtiene el usuario del JWT y guarda/lee sus registros en PostgreSQL.

## 4. Comprobaciones

- API: `curl http://localhost:3000/health`.
- Backend: desde `apps/api`, ejecutar `npm install && npx prisma validate && npm run build && npm test`.
- Android: desde `apps/mobile`, ejecutar `flutter analyze && flutter test && flutter build apk --debug --dart-define=API_URL=http://IP_LAN_DEL_ORDENADOR:3000`.
- En el Samsung: crear una cuenta de prueba, iniciar sesión, registrar una lectura de prueba claramente identificada como tal y comprobar que aparece al recargar.

No introduzcas lecturas ficticias como datos clínicos reales. No utilices cuentas ni contraseñas reales en pruebas automatizadas.

## 5. Seguridad y límites

- No subir `.env`, tokens, contraseñas ni claves al repositorio.
- No exponer PostgreSQL a la red local si no es necesario.
- El modo HTTP solo es para desarrollo en una red de confianza.
- La capa de sensores no implica sincronización real: requiere APIs/SDK y autorización del fabricante.
- DIABETA es una herramienta de apoyo; no calcula ni modifica dosis de insulina.

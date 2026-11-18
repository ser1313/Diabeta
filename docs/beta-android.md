# Beta de pruebas en un móvil Android (Samsung)

Versión **solo para pruebas**: usa datos ficticios, no datos de salud reales.
La calculadora de bolo está **deshabilitada** (issue #52) y la app muestra un
distintivo «BETA».

## 1. API de pruebas con HTTPS
El APK beta es una compilación *release* y solo admite `https://`. El repositorio
no incluye ninguna URL: hay que elegir dónde se ejecuta la API (**decisión pendiente**).

| Opción | Cómo | Ventajas | Inconvenientes |
|---|---|---|---|
| **A. Tu ordenador + túnel HTTPS** (recomendada para empezar) | `docker compose up --build` en este repositorio y, por ejemplo, `cloudflared tunnel --url http://localhost:3000` (Cloudflare Tunnel) o Tailscale Funnel | Gratis; los datos no salen de tu equipo; no hace falta desplegar nada | La URL cambia en cada sesión (hay que actualizar el secreto y recompilar); el ordenador debe estar encendido; mientras el túnel está activo, la API es accesible desde Internet |
| **B. Alojamiento gestionado** (Render, Fly.io, Railway…) con PostgreSQL gestionado | Desplegar `apps/api` (Dockerfile) | URL estable | Requiere cuenta, coste y **autorización expresa**: no se ha desplegado nada |

Variables de la API de pruebas (en `.env` para la opción A):

| Variable | Valor |
|---|---|
| `JWT_SECRET` | Aleatorio y largo (`openssl rand -base64 48`); nunca reutilizar el de producción |
| `NODE_ENV` | `production` |
| `CORS_ORIGIN` | Obligatoria en producción. La app móvil no envía `Origin`, así que basta con la URL HTTPS de la propia API |
| `POSTGRES_PASSWORD` | Aleatoria, distinta de `diabeta_dev` |
| `CLINICAL_CALCULATOR_ENABLED` | **No definir** (la calculadora queda deshabilitada) |

Comprueba desde el móvil que `https://TU-URL/health` responde `{"status":"ok"}`.

## 2. Compilar el APK beta
1. En GitHub: **Settings → Secrets and variables → Actions → New repository secret**:
   `BETA_API_URL` = la URL HTTPS de la API (sin `/` final). Es un secreto para que
   no aparezca en los logs, que son públicos.
2. **Actions → Diabeta beta APK → Run workflow** (después de fusionar), o vuelve a
   ejecutar el workflow en la PR.
3. Al terminar, la sección **Artifacts** de la ejecución contiene
   `diabeta-beta-<commit>.apk`, sin comprimir. El resumen de la ejecución
   muestra su SHA-256. Caduca a los 7 días; no es una release.

Sin el secreto, el workflow comprueba que la compilación funciona, pero no publica APK.

## 3. Instalar en el Samsung
1. Desde el navegador del móvil, con tu sesión de GitHub, abre la ejecución y
   descarga el `.apk` de **Artifacts** (o descárgalo en el PC y pásalo por USB).
2. Al abrirlo, Android pedirá permitir **Instalar aplicaciones desconocidas** para
   el navegador o «Mis archivos». Concede el permiso solo para esa instalación y
   retíralo después (Ajustes → Aplicaciones → Acceso especial).
3. Si Play Protect avisa, es porque la app no viene de Google Play: instálala
   solo si el SHA-256 coincide con el del resumen de la ejecución.

## Limitaciones conocidas
- El APK se firma con la clave de depuración del runner, que cambia en cada
  ejecución: para instalar una beta nueva hay que **desinstalar la anterior**, lo
  que borra sus datos locales. Para poder actualizar sin desinstalar hace falta una
  clave de firma propia guardada como secreto (**decisión pendiente**).
- En un repositorio público, cualquier usuario con sesión en GitHub puede descargar
  los artefactos, y el APK contiene la URL de la API de pruebas. Usa solo datos
  ficticios y apaga el túnel cuando no lo uses.

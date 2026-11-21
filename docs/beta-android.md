# Beta de pruebas en un móvil Android (Samsung)

Versión **solo para pruebas y solo con datos ficticios**: nunca datos de salud
reales ni tu email personal; usa direcciones como `prueba1@example.invalid`.
La calculadora de bolo está **deshabilitada** en la API y en la app (issue #52) y
la app muestra un distintivo «BETA».

## 1. API de pruebas con HTTPS
El APK beta es una compilación *release* y solo admite `https://`. El repositorio
no contiene ninguna URL. Dónde ejecutar la API es una **decisión pendiente**:

| Opción | Quién puede acceder a la API | Notas |
|---|---|---|
| **A. Tailscale Serve** (recomendada) | Solo los dispositivos de tu red Tailscale (PC y Samsung con la app Tailscale) | HTTPS con certificado válido (`https://<equipo>.<tailnet>.ts.net`). **No** es accesible desde Internet. No usar *Funnel*, que la hace pública |
| **B. Túnel público** (Cloudflare Tunnel, Tailscale Funnel…) | **Cualquiera en Internet** que conozca o adivine la URL, mientras el túnel esté abierto | El proveedor del túnel termina el TLS y ve el tráfico. Ver los riesgos abajo |
| **C. Alojamiento gestionado** (Render, Fly.io…) | Público | Requiere cuenta, coste y **autorización expresa**: no se ha desplegado nada |

### Beta privada en Windows

Desde la raíz del repositorio, con Docker Desktop en modo Linux:

```powershell
.\scripts\beta-windows.ps1 -Action Start
```

El script arranca el proyecto aislado `diabeta-beta-local`. La API escucha en
`127.0.0.1:3000` y PostgreSQL en `127.0.0.1:55432`. Las claves se generan en el
archivo ignorado `.env.beta.local` y se conservan entre arranques.

Con Tailscale Serve ya configurado para el puerto 3000, abre `/health` en el
Samsung usando la URL HTTPS de tu red privada. Si responde `status: ok`,
compila el APK en el PC con Flutter y el SDK de Android configurados:

```powershell
.\scripts\beta-windows.ps1 -Action Build -ApiUrl 'https://EQUIPO.TAILNET.ts.net'
```

El script muestra la ruta y el SHA-256 del APK. Puedes copiarlo por USB.
Al terminar las pruebas, `./scripts/beta-windows.ps1 -Action Stop` detiene la
API y PostgreSQL y conserva el volumen de pruebas.

### Riesgos de un túnel público (opción B) y medidas obligatorias
Mientras el túnel está abierto, la API queda **accesible desde Internet**:
- Cualquiera puede llamar a `/auth/register` y crear cuentas, e intentar entrar
  en las existentes.
- Detrás del túnel todas las peticiones llegan con la misma IP, así que el límite
  de 10 intentos de login por minuto es compartido: protege frente a la fuerza
  bruta, pero un tercero podría bloquear tus pruebas temporalmente.
- Los registros del proveedor del túnel pueden contener la URL y metadatos.

Medidas:
1. **Solo datos ficticios.** Base de datos de pruebas separada, que se borra al
   terminar (ver más abajo).
2. Expón **solo el puerto de la API** (`localhost:3000`), nunca PostgreSQL. En
   `docker-compose.yml` la base de datos ya escucha solo en `127.0.0.1`, y con
   `API_BIND_HOST=127.0.0.1` la API tampoco queda abierta a tu red local.
3. `JWT_SECRET` y `POSTGRES_PASSWORD` aleatorios y exclusivos de la beta.
4. Abre el túnel solo mientras pruebas y **ciérralo al terminar** (Ctrl+C). No
   compartas la URL en issues, PR ni chats.

### Arrancar la API de pruebas aislada
Crea `.env.beta` en la raíz del repositorio (está excluido de Git por `.gitignore`):
```
JWT_SECRET=<salida de: openssl rand -base64 48>
POSTGRES_PASSWORD=<salida de: openssl rand -base64 24>
NODE_ENV=production
CORS_ORIGIN=https://TU-URL-HTTPS
API_BIND_HOST=127.0.0.1
# CLINICAL_CALCULATOR_ENABLED no se define: la calculadora queda deshabilitada.
```
```
docker compose -p diabeta-beta --env-file .env.beta up --build
```
`-p diabeta-beta` crea contenedores y un volumen propios, separados de tu entorno de
desarrollo. `CORS_ORIGIN` es obligatoria en producción; la app móvil no envía
`Origin`, así que basta con la propia URL HTTPS. Para terminar y **borrar los
datos de prueba**:
```
docker compose -p diabeta-beta down -v
```
Comprueba desde el móvil que `https://TU-URL/health` responde `{"status":"ok"}`.

## 2. Compilar el APK beta
La URL de la API **no** debe estar al alcance de los pull requests:

1. **Settings → Environments → New environment** → `beta`:
   - *Required reviewers*: tú.
   - *Deployment branches*: solo `main`.
   - *Environment secrets*: `BETA_API_URL` = URL HTTPS de la API, sin `/` final.
   No crees `BETA_API_URL` como secreto de repositorio.
2. **Actions → Diabeta beta APK → Run workflow** sobre `main` (después de fusionar)
   y aprueba la ejecución cuando GitHub lo pida.

En los pull requests solo se ejecuta `verify-release`, que compila sin secretos
(con el dominio reservado `example.invalid`), comprueba que el APK no es depurable
ni permite HTTP sin cifrar, y no publica nada.

Alternativa sin GitHub: compilar en tu PC con Flutter 3.29.0:
```
cd apps/mobile
flutter build apk --release --dart-define=API_URL=https://TU-URL --dart-define=DIABETA_BETA=true
```

## 3. Descarga directa en el Samsung, sin Artifacts
El APK no se publica en ningún sitio: tu PC lo sirve al móvil por tu Wi-Fi durante
unos minutos.

1. Obtén el APK en el PC: compílalo (§2, alternativa) o descárgalo una vez con
   `gh run download <id-de-ejecución> -n diabeta-beta-<commit>.apk`.
2. Con el PC y el Samsung en la **misma Wi-Fi de confianza** (no redes públicas):
   ```
   python3 scripts/beta_serve_apk.py ruta/diabeta-beta.apk
   ```
   El script:
   - muestra el SHA-256 y una URL de la forma `http://<IP-del-PC>:<puerto>/<token>/<archivo>.apk`;
   - escucha solo en la IP de tu Wi-Fi (`--host` para elegir otra; rechaza `0.0.0.0`);
   - responde 404 a cualquier ruta sin el token aleatorio;
   - se apaga tras la **primera descarga completa** o a los 10 minutos (`--minutes`).

   Es HTTP dentro de tu red local, solo para transferir el archivo: comprueba el
   SHA-256 antes de instalar.
3. Escribe la URL en el navegador del Samsung (Samsung Internet o Chrome) y descarga.
4. Sin Wi-Fi compartida: cable USB (copiar a *Descargas*), Quick Share o
   `adb install diabeta-beta.apk`.

## 4. Instalar
1. Abre el APK descargado. Android pedirá permitir **Instalar aplicaciones
   desconocidas** para el navegador o *Mis archivos*: concédelo solo para esta
   instalación y retíralo después (Ajustes → Aplicaciones → Acceso especial).
2. Si Play Protect avisa, es porque la app no viene de Google Play: instálala solo
   si el SHA-256 coincide.

## Limitaciones conocidas
- **Firma:** el APK se firma con una clave de depuración que cambia en cada
  compilación. Para instalar una beta nueva hay que desinstalar la anterior, lo que
  borra sus datos locales. Una clave propia en el entorno `beta` es una **decisión
  pendiente**.
- **URL dentro del APK:** el APK contiene la URL de la API de pruebas. No lo
  compartas. Los artefactos de un repositorio público pueden descargarlos usuarios
  con sesión en GitHub, por eso el workflow solo sube el APK en ejecuciones
  manuales aprobadas en el entorno `beta`, con caducidad de 7 días.

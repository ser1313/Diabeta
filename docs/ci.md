# Integración continua (GitHub Actions)

Workflow: `.github/workflows/ci.yml`. Jobs `api` (NestJS + Prisma) y `mobile`
(Flutter: análisis, pruebas y APK de depuración publicado como artefacto).

## Runner
| Job | Imagen | Motivo |
|---|---|---|
| `api`, `mobile` | `ubuntu-24.04` | LTS en GA. `ubuntu-latest` migra a Ubuntu 26.04 desde el 19-10-2026, cuyo Java por defecto es 25 (incompatible con Gradle 8.10.2). Ubuntu 24.04 trae Java 17 por defecto y el mismo Android SDK (build-tools 34–37, plataformas 34–37). |

Fuente: `actions/runner-images`, `images/ubuntu/Ubuntu2404-Readme.md` y
`Ubuntu2604-Readme.md` (imágenes 20261111).

## Acciones
Fijadas por SHA de commit, verificado clonando el tag publicado. Todas usan
`runs.using: node24` (o son compuestas), por lo que no generan la advertencia
de Node.js 20 obsoleto.

| Acción | Versión | SHA | Runtime | Antes |
|---|---|---|---|---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` | node24 | v4.2.2 (node20) |
| `actions/setup-node` | v7.1.0 | `949feb2413d6458794dcd2491c4babbbce0c15c1` | node24 | v4.4.0 (node20) |
| `actions/setup-java` | v6.2.0 | `77dd5b2ce225ea11469928ac317850245a74ae78` | node24 | v4.7.1 (node20) |
| `subosito/flutter-action` | v2.23.0 | `1a449444c387b1966244ae4d4f8c696479add0b2` | compuesta | v2.16.0 |
| `actions/upload-artifact` | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` | node24 | v4.6.2 (node20) |

Notas de compatibilidad revisadas:
- `checkout` v7 bloquea por defecto PR de forks con `pull_request_target`/`workflow_run`; este workflow no usa esos eventos.
- `setup-node` v7 elimina el `NODE_AUTH_TOKEN` ficticio cuando se usa `registry-url`; aquí no se usa.
- `setup-java` v6.2.0 en lugar de v6.3.0: la 6.3.0 se publicó el 13-11-2026; se prefiere la anterior, ya asentada.
- `flutter-action` solo usa `actions/cache` si se activa `cache: true`; no está activado.
- `upload-artifact` v7 mantiene `name`, `path`, `if-no-files-found` y `retention-days`; `archive` sigue siendo `true` por defecto (se publica un zip).

## Herramientas
| Herramienta | Versión | Dónde |
|---|---|---|
| Node.js (API) | 22 | `setup-node` |
| Java | 17 (Temurin) | `setup-java` |
| Flutter / Dart | 3.29.0 / 3.7.0 | `flutter-action` |
| Gradle | 8.11.1 | `apps/mobile/android/gradle/wrapper` |
| Android Gradle Plugin / Kotlin | 8.9.3 / 2.1.0 | `apps/mobile/android/settings.gradle` |
| compileSdk / targetSdk | 36 / valor de Flutter (35) | `apps/mobile/android/app/build.gradle` |
| NDK | 27.0.12077973 | `apps/mobile/android/app/build.gradle` |

Flutter y las librerías no se han actualizado: requieren su propia PR con pruebas.

## Auditoría de avisos y dependencias (issue #64)
**Android SDK.** `flutter_secure_storage` 10.x compila con la API 36 y Flutter 3.29
deja la app en 35, lo que provocaba `requires Android SDK version 36`. Se fija
`compileSdk = 36`; `targetSdk` no cambia (no altera el comportamiento en ejecución).
AGP 8.7.3 avisaba entonces de que solo está probado hasta compileSdk 35. AGP 8.9.3
es la versión mínima con `MAX_RECOMMENDED_COMPILE_SDK_VERSION = 36` (leído del
bytecode de su JAR en CI) y exige Gradle ≥ 8.11.1. No se usa
`android.suppressUnsupportedCompileSdk`: el aviso se corrige, no se oculta.

**npm.** `node-abort-controller` llegaba por `@nestjs/cli` 11 →
`fork-ts-checker-webpack-plugin` (todas sus versiones lo usan). `@nestjs/cli` 12
lo convierte en *peer* opcional solo para webpack; este proyecto compila con
`tsc`. El `dist` generado es idéntico con la CLI 11 y la 12. Sin `overrides`.

**pub.** Las 41 versiones nuevas que menciona `flutter pub get` exigen Dart
3.8–3.11 / Flutter 3.35–3.41 (p. ej. `shared_preferences` 2.5.6, `url_launcher`
6.3.3, `flutter_secure_storage` 11.2.0). Ninguna está descontinuada, retirada ni
afectada por avisos de seguridad: son actualizaciones opcionales que dependen de
actualizar Flutter.

**Pendiente (fuera de alcance):** plan detallado en `docs/migraciones.md`.
- `Deprecated Gradle features … incompatible with Gradle 9.0` (solo con
  `--verbose`): viene de `Project.exec` en el plugin Gradle de Flutter 3.29
  (`flutter.groovy`), obsoleto desde Gradle 8.11. Se resuelve actualizando Flutter.
- `npm audit`: tras #67 quedaban 6 altas de desarrollo (`picomatch` 4.0.7,
  GHSA-fc5q-39xc-vjpf). Ese aviso ya no figura en la base de datos de npm;
  `npm audit` = 0 y `npm audit --omit=dev` = 0. Ver `docs/migraciones.md` §3.

## Dependencias de la API (issue #66, PR #67)
- `apps/api/package-lock.json` versionado; CI y Docker instalan con `npm ci`.
- `overrides`: `deepmerge-ts` ^8.0.2 solo para `@prisma/config`
  (GHSA-ggr8-5vv4-36mx). Retirar al migrar a Prisma 7 (`docs/migraciones.md` §1).
- `overrides`: `effect` 3.22.4 solo para `@prisma/config` (GHSA-7589-6fvf-x4pw, ReDoS en
  `Schema.TemplateLiteral`, que `@prisma/config` no usa). Prisma 6.19.3 fija la 3.21.0 y
  Prisma 7.10.1 la 3.20.0. Retirar cuando Prisma publique una versión con effect > 3.22.0.
- Imagen Docker: `npm prune --omit=dev` tras compilar; `prisma` es dependencia de
  producción porque el contenedor ejecuta `prisma migrate deploy`. La imagen no
  incluye la CLI de Nest ni `picomatch`.
- Actualizar dependencias de forma explícita (`npm update` o `npm install pkg@x`)
  y revisar el diff del lockfile en la PR.

## Mantenimiento
Para actualizar una acción: obtener el commit del tag con
`git ls-remote https://github.com/OWNER/REPO.git 'refs/tags/vX.Y.Z^{}'` (o clonar
el tag y `git rev-parse HEAD`), comprobar `runs.using` en `action.yml` y
actualizar esta tabla.

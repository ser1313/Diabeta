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

## Herramientas (sin cambios)
| Herramienta | Versión | Dónde |
|---|---|---|
| Node.js (API) | 22 | `setup-node` |
| Java | 17 (Temurin) | `setup-java` |
| Flutter / Dart | 3.29.0 / 3.7.0 | `flutter-action` |
| Gradle | 8.10.2 | `apps/mobile/android/gradle/wrapper` |
| Android Gradle Plugin / Kotlin | 8.7.3 / 2.1.0 | `apps/mobile/android/settings.gradle` |
| NDK | 27.0.12077973 | `apps/mobile/android/app/build.gradle` |

Flutter, Gradle, AGP y librerías no se han actualizado: requieren su propia
PR con pruebas.

## Mantenimiento
Para actualizar una acción: obtener el commit del tag con
`git ls-remote https://github.com/OWNER/REPO.git 'refs/tags/vX.Y.Z^{}'` (o clonar
el tag y `git rev-parse HEAD`), comprobar `runs.using` en `action.yml` y
actualizar esta tabla.

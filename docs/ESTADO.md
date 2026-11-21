# Estado del proyecto y traspaso (actualizado 21-11-2026)

Documento para retomar el trabajo en una sesión nueva. No contiene secretos.

## Arquitectura (congelada v2.7)
- `apps/api`: NestJS 11 + Prisma 6.19 (en `main`) + PostgreSQL 16. Node 22. `npm ci` con `package-lock.json`.
- `apps/mobile`: Flutter 3.29.0 / Dart 3.7. Android: AGP 8.9.3, Gradle 8.11.1, Kotlin 2.1.0, compileSdk 36, minSdk 23, Java 17.
- CI (`.github/workflows/ci.yml`): `ubuntu-24.04`, acciones fijadas por SHA (node24). Jobs `api` (audit, prisma, build, test) y `mobile` (analyze, test, APK debug).
- Detalle de versiones y avisos: `docs/ci.md`. Planes de migración: `docs/migraciones.md`.

## Decisiones técnicas vigentes
- **Seguridad clínica:** ninguna recomendación de dosis en producción. La calculadora de bolo está **deshabilitada por defecto**: la API devuelve 403 salvo con `CLINICAL_CALCULATOR_ENABLED=true` y la app la oculta salvo con `--dart-define=DIABETA_CLINICAL_CALCULATOR=true`. No modificar las fórmulas sin revisión profesional (issue #52).
- Con glucosa < 70 mg/dL no se calcula dosis: aviso en rojo, en la API y también en la app.
- Contenido educativo (`apps/mobile/lib/education`): pendiente de revisión sanitaria, oculto en release.
- Dependencias: lockfile versionado; imagen Docker sin dependencias de desarrollo. `overrides` acotados a `@prisma/config`: `deepmerge-ts` ^8.0.2 (solo Prisma 6) y `effect` 3.22.4 (GHSA-7589-6fvf-x4pw; también necesario en Prisma 7). CI falla con vulnerabilidades altas en producción (`npm audit --omit=dev`).
- Secretos: nunca en el código ni en logs. La URL de la beta va en el secreto de entorno `beta` (no de repositorio).
- Avisos: se corrigen, no se ocultan (p. ej. no usar `android.suppressUnsupportedCompileSdk`).

## PR abiertas
| PR | Contenido | Estado |
|---|---|---|
| #69 `feat/prisma-7` | Prisma 7.10 + `@prisma/adapter-pg`, `prisma.config.ts`; sin cambios de esquema | CI verde; pendiente de revisión. **Al actualizarla con `main` tras #70, añadir el override de `effect`** (Prisma 7 trae 3.20.0) |
| #70 `feat/beta-android` | Beta Android: protección < 70, calculadora deshabilitada, workflow `beta-apk.yml`, guía `docs/beta-android.md`, servidor LAN `scripts/beta_serve_apk.py` | Ver abajo |

### PR #70: estado
- Hecho: protección < 70 (rama `feat/calculator-hypoglycemia-guard`), corrección del hallazgo de Codex (respuestas obsoletas de la calculadora), secreto solo en el job manual `beta-apk` con `environment: beta` y desde `main`, `verify-release` sin secretos en las PR, `npm audit` en CI, comprobaciones del APK (`scripts/check-release-apk.sh`), riesgos del túnel documentados y descarga por Wi-Fi sin Artifacts.
- Pruebas: API 25, Flutter 88. `npm audit` de producción: 0 (con el override de `effect`).
- No fusionar hasta revisar. Tras fusionar #69 o #70, actualizar la otra con `main`.

## Decisiones pendientes (propietario)
1. API de pruebas: Tailscale Serve (privada, recomendada), túnel público o alojamiento gestionado (requiere autorización).
2. Crear el entorno `beta` (revisor obligatorio, rama `main`) y su secreto `BETA_API_URL`.
3. Clave de firma propia para la beta (ahora se firma con una clave de depuración distinta en cada compilación).
4. Repositorio público: valorar hacerlo privado durante la beta.
5. Revisión profesional de la calculadora y del umbral de 70 mg/dL (#52) y del contenido educativo (#58).
6. Migración de Flutter 3.47 (`docs/migraciones.md` §2): decidir `minSdk` 24 y `targetSdk` 36.

## Tareas siguientes
- Revisar y fusionar #69 y #70; después, migrar a Flutter 3.47 en una PR propia.
- Versionar `pubspec.lock` (con la migración de Flutter).

## Procedimientos
- **Pruebas locales:**
  - API: `cd apps/api && npm ci && DATABASE_URL=postgresql://u:p@localhost:5432/db npx prisma generate && npm test`.
  - App: `cd apps/mobile && flutter analyze && flutter test`.
- **Ver avisos reales de Gradle:** `flutter build apk --debug --verbose` (en CI, en un paso temporal que se elimina antes de pedir revisión).
- **Comprobar Docker:** `docker compose -p <nombre> up --build` con datos ficticios; `/health`, registro, login, 401 sin token y `_prisma_migrations`.
- **Beta en el Samsung:** `docs/beta-android.md`.
- **Al trabajar con IA:** leer este archivo, `docs/ci.md`, `docs/migraciones.md` y `SECURITY.md`; rama propia por tarea; CI verde antes de pedir revisión; no fusionar.

# Plan de migraciones: Prisma 7 y Flutter 3.47 (issue #66, fase 2)

Documento de planificación. **No ejecuta ninguna migración.** Cada una irá en una
PR propia, con CI verde y revisión. No afecta a la lógica clínica: los cálculos y
las fórmulas no cambian en ninguna de las dos migraciones.

Evidencia obtenida el 18-11-2026 probando las versiones nuevas sobre copias del
código de `main` (`af58a90`), fuera del repositorio.

---

## 1. Prisma 6.19 → 7.10

### Motivo
- Elimina la dependencia de `deepmerge-ts` 7 (GHSA-ggr8-5vv4-36mx), hoy mitigada con
  un `overrides` acotado (PR de la fase 1), que podrá retirarse.
- Prisma 6 dejará de recibir correcciones.

### Cambios incompatibles comprobados
| Cambio | Evidencia | Impacto en Diabeta |
|---|---|---|
| `url` ya no se admite en `datasource` de `schema.prisma` | `prisma validate` 7.10.1 → P1012 *“The datasource property `url` is no longer supported in schema files”* | Mover la URL a `prisma.config.ts` (`datasource.url: env('DATABASE_URL')`) |
| `PrismaClient` exige un *driver adapter* | `new PrismaClient()` → *“A driver adapter is required to connect to your database”* | Añadir `@prisma/adapter-pg` (+ `pg`) y crear el cliente con `new PrismaPg({ connectionString })` en `src/prisma.service.ts` |
| Node `^20.19 \|\| ^22.12 \|\| >=24` | `engines` de `prisma@7.10.1` | Compatible (CI y Docker usan Node 22) |
| TypeScript ≥ 5.4 | `peerDependencies` de `@prisma/client@7.10.1` | Compatible (5.9) |
| Con `prisma.config.ts` no se cargan variables de entorno automáticamente | Mensaje *“Prisma config detected, skipping environment variable loading”* | En Docker y CI ya se pasan como variables reales; en local, documentar `--env-file` |

Con esos dos cambios, Prisma 7.10.1 valida el esquema actual y genera el cliente
(`prisma-client-js` sigue funcionando). El modelo de datos y las migraciones SQL
existentes **no cambian**.

### Plan
1. Rama propia. Añadir `prisma.config.ts`, quitar `url` del esquema, añadir
   `@prisma/adapter-pg` y `pg`, y adaptar `PrismaService` (sin tocar consultas).
2. Eliminar el `overrides` de `deepmerge-ts`.
3. Comprobar que no hay deriva de esquema:
   `prisma migrate diff --from-migrations prisma/migrations --to-schema-datamodel prisma/schema.prisma --shadow-database-url …` → vacío.
4. Pruebas: `npm test` y prueba de humo en Docker con PostgreSQL 16 y datos
   ficticios (health, registro, login, 401 sin token, `_prisma_migrations` = 5),
   igual que en la fase 1, comparando con la imagen anterior.
5. Despliegue (fuera de esta issue): copia de seguridad previa
   (`pg_dump -Fc`) y prueba de restauración en un entorno aparte; `migrate deploy`
   no debe aplicar migraciones nuevas. Vuelta atrás: imagen anterior + la misma BD.

### Riesgos
- Cambio en la gestión de conexiones (pool de `pg` en lugar del motor de Rust):
  vigilar errores y latencia tras desplegar.
- Bajo riesgo para los datos: no hay migraciones nuevas.

---

## 2. Flutter 3.29.0 → 3.47.9

### Por qué 3.47.9 y no 3.50.0
3.50.0 es la estable actual, pero se publicó el 09-11-2026. 3.47.9 es la última
de la rama anterior, ya madura. Revaluar 3.50.x cuando lleve más tiempo publicada.

### Motivo
- Elimina el aviso de Gradle 9: el plugin de Flutter 3.47 usa `ExecOperations` en
  lugar de `Project.exec`.
- Permite las versiones nuevas de los paquetes (Dart ≥ 3.8–3.11).

### Resultado con el código actual (Flutter 3.47.9, Dart 3.13.7)
- `flutter test`: **77/77** sin cambios.
- `flutter analyze`: 3 avisos de API obsoleta:
  - `DropdownButtonFormField.value` → `initialValue` (`lib/main.dart:186`, `lib/settings.dart:81`).
  - `SemanticsData.hasFlag` → `flagsCollection` (`test/glucose_education_test.dart:238`).
- Paquetes: desaparece el bloqueo de SDK; quedan como mayores opcionales
  `flutter_secure_storage` 11, `flutter_lints` 6, `cupertino_icons` 2 y `qr` 4.

### Requisitos de Android que impone Flutter 3.47 (de `DependencyVersionChecker.kt`)
| Componente | Actual | Error si < | Aviso si < |
|---|---|---|---|
| Gradle | 8.11.1 | 8.14 | 9.1.0 |
| AGP | 8.9.3 | 8.11.1 | 9.0.1 |
| Kotlin (KGP) | 2.1.0 | 2.2.20 | 2.3.20 |
| `minSdk` | 23 | 23 | **24** |
| `compileSdk` por defecto | 36 (fijado) | — | — |

### Decisiones de producto necesarias antes de migrar
- **`minSdk` 23 → 24:** deja fuera Android 6.0. Hay que decidir si se acepta o si
  se mantiene 23 con aviso.
- **`targetSdk`:** con 3.47 el valor por defecto sube a 36, lo que cambia el
  comportamiento en ejecución (por ejemplo, *edge-to-edge* obligatorio). Requiere
  revisar la interfaz en un dispositivo o emulador con Android 15/16, o fijar
  temporalmente el valor actual.

### Plan
1. Rama propia: Flutter 3.47.9 en CI (`flutter-version`), AGP 9.0.x, Gradle 9.1+
   y Kotlin 2.3.20+, verificando la compatibilidad AGP 9 ↔ Kotlin ↔ Gradle con la
   misma técnica de la issue #64 (sonda en CI y build `--verbose` sin avisos).
2. Sustituir las 3 APIs obsoletas, sin cambios de comportamiento.
3. Aplicar las decisiones sobre `minSdk` y `targetSdk`.
4. Versionar `pubspec.lock` (recomendado para aplicaciones).
5. CI: `flutter analyze` sin avisos, `flutter test`, APK; revisión manual de la
   interfaz en emulador antes de publicar.
6. Paquetes mayores (`flutter_secure_storage` 11, etc.) en una PR posterior.

### Riesgos
- AGP 9 es una versión mayor (cambios en la DSL de Gradle): es el punto de mayor
  riesgo de que falle el build.
- `targetSdk` 36 afecta al comportamiento visible para el usuario.

---

## 3. `picomatch` (GHSA-fc5q-39xc-vjpf)
No existe versión corregida (la última, 4.0.7, es vulnerable). Llega por
`@nestjs/cli` → `@angular-devkit/core` 22.2.x, que la fija en 4.0.7. Tras la fase 1
ya no está en la imagen de producción; solo se usa al compilar, con patrones del
propio proyecto, sin entrada externa. Acción: revisar cuando se publique
`picomatch` ≥ 4.0.8 o una nueva versión de `@angular-devkit`/`@nestjs/cli`.

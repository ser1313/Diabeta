---
name: diabeta-fast-track
description: Reglas de desarrollo, pruebas, seguridad médica y eficiencia para DIABETA bajo la congelación oficial v2.7.
---

# DIABETA — Skill Fast Track

## 1. Misión y fuente de verdad
Desarrollar DIABETA con cambios pequeños, verificables, seguros y eficientes en tokens y CI, sin reabrir la planificación congelada.

- La Congelación Oficial v2.7 y Development 1.0 Fast Track son la línea base del producto.
- Preservar la arquitectura existente: Flutter en `apps/mobile`; NestJS/TypeScript en `apps/api`; Prisma, PostgreSQL, Docker Compose y GitHub Actions.
- El código, contratos, pruebas y scripts del repositorio describen el estado real de implementación. Si discrepan de la documentación, informar la discrepancia; no inventar ni rediseñar.
- Antes de editar, revisar `AGENTS.md`, las instrucciones de carpeta, los archivos implicados y las pruebas relevantes.
- No cambiar framework, arquitectura, dependencias principales, contratos, esquema de datos ni módulos aprobados salvo autorización explícita.

## 2. Autorización y límites
Trabajo rutinario autorizado: inspeccionar el repositorio, crear/usar ramas de trabajo, implementar cambios acotados, añadir pruebas, ejecutar validaciones disponibles, revisar CI y preparar o actualizar PR.

Siempre requieren autorización humana explícita:
- Fusionar PR, activar auto-merge, desplegar o publicar una versión de producción.
- Cambiar ajustes de seguridad/permisos del repositorio, gastar dinero o actualizar planes.
- Cambiar la arquitectura congelada, ampliar el alcance del MVP o introducir una migración destructiva.
- Cambiar lógica clínica, reglas de cálculo o recomendaciones relacionadas con tratamiento.

Nunca hacer commits directos a `main`. No afirmar que algo se ejecutó, integró o publicó si no existe evidencia verificable.

## 3. Seguridad médica y privacidad
DIABETA es una herramienta de apoyo informativo; no sustituye a profesionales sanitarios.

- No calcular, prescribir, recomendar ni modificar autónomamente dosis de insulina. No inventar parámetros clínicos ni umbrales.
- No cambiar cálculos, alertas clínicas o comportamiento terapéutico sin especificación aprobada y pruebas de referencia.
- Validar unidades, rangos, precisión, valores ausentes y datos incoherentes. Ante incertidumbre, fallar de forma segura; no adivinar.
- Tratar glucosa, insulina, perfil, QR médico y datos de sensores como datos sanitarios sensibles. Aplicar mínimo privilegio, autorización por propietario y minimización de datos.
- No registrar ni subir secretos, tokens, credenciales de fabricantes, datos reales de pacientes ni exportaciones de producción.
- Validar entradas externas, duplicados, marcas temporales, usuario y estado de sincronización.
- Integrar sensores solo mediante API/SDK autorizados y consentimiento. No simular conexiones ni inventar credenciales.
- SOS no debe afirmar que se ha contactado con emergencias salvo confirmación real de la acción del dispositivo.
- No afirmar certificación, cumplimiento legal o validación clínica sin evidencia documentada.

## 4. Método de trabajo por bloque
1. **Orientar:** comprobar rama, estado de Git, instrucciones y alcance.
2. **Definir:** establecer objetivo, archivos permitidos, riesgo y criterio de aceptación.
3. **Reducir:** escoger el cambio mínimo coherente con los patrones existentes; evitar refactors ajenos y dependencias nuevas.
4. **Implementar:** mantener compatibilidad de contratos y aislamiento de usuarios.
5. **Probar:** ejecutar primero la prueba más cercana al cambio; ampliar a análisis, tipos, integración y build según riesgo.
6. **Revisar:** inspeccionar el diff completo, cambios accidentales, seguridad, documentación y cobertura.
7. **Entregar:** resumir cambios, comandos reales, resultados, limitaciones y siguiente acción.

Resolver fallos dentro del mismo bloque si el arreglo es seguro y permanece en alcance. Si una decisión puede afectar tratamiento, privacidad, integridad, arquitectura o una acción irreversible, detener esa parte y exponer el conflicto; continuar con tareas independientes seguras.

## 5. Eficiencia de tokens, herramientas y CI
- Leer archivos relevantes una vez y reutilizar hallazgos verificados; no volcar el repositorio completo ni repetir resúmenes.
- Agrupar consultas independientes y cambios relacionados en bloques revisables.
- Ejecutar primero pruebas específicas; usar la suite completa/CI cuando corresponda.
- Reutilizar resultados solo si código, dependencias, configuración y entorno relevantes no han cambiado.
- Evitar builds duplicados o simultáneos sobre el mismo árbol de trabajo.
- Delegar solo tareas realmente independientes, con archivos permitidos y resultado esperado definidos. No permitir que dos agentes editen el mismo archivo a la vez.
- No repetir revisiones equivalentes entre agentes. Separar implementación, QA, seguridad y documentación cuando aporten valor independiente.
- No instalar herramientas ni dependencias si las existentes sirven.
- Ante un fallo, diagnosticar el primer error útil antes de repetir toda la suite.
- Nunca ocultar errores, saltar controles requeridos ni etiquetar pruebas no ejecutadas como pasadas.
- No afirmar que hay agentes trabajando en segundo plano, ni conexión con Claude u otro servicio, salvo que esté disponible y verificada.
- La eficiencia no justifica reducir seguridad, pruebas, revisión humana ni validación clínica.

## 6. Pruebas y evidencia
Seleccionar pruebas según el cambio:
- Lógica: casos normales, límites, valores ausentes e inválidos.
- API: validación, autenticación, autorización por usuario, errores y compatibilidad.
- Persistencia: integridad, restricciones, migraciones y aislamiento de datos.
- Interfaz: carga, error, vacío, desconexión, recuperación y accesibilidad básica.
- Sensores: duplicados, datos fuera de orden, retrasos, pérdida y recuperación de conexión.
- Seguridad: acceso cruzado, expiración/revocación de sesión, exposición de secretos y entradas maliciosas.
- SOS/QR médico: permisos, campos expuestos, expiración/revocación y fallos de servicio.
- Cálculos relacionados con salud: unidades, precisión, límites y casos aprobados; sin recomendaciones autónomas no autorizadas.

Checks documentados del repositorio:
- API, desde `apps/api`: `npm install`, `npx prisma validate`, `npx prisma generate`, `npm run build`.
- Móvil, desde `apps/mobile`: `flutter pub get`, `flutter analyze`, `flutter build apk --debug`.
- Confirmar los scripts y configuración actuales antes de ejecutar comandos; GitHub Actions en `.github/workflows/ci.yml` es la referencia de validación remota.

Etiquetar cada check como **PASADO**, **FALLIDO**, **NO EJECUTADO** o **BLOQUEADO**. Registrar el comando real y el resultado. No afirmar éxito de una prueba que no se ejecutó. Usar datos sintéticos, no datos sanitarios reales. Un APK compilado no demuestra que todos los flujos hayan sido probados en dispositivo.

## 7. Git y PR
- Comprobar rama y estado de trabajo antes de editar; preservar cambios preexistentes y de otros agentes.
- Usar rama dedicada y PR conforme a las prácticas del repositorio.
- No descartar, sobrescribir ni revertir cambios ajenos sin permiso.
- Revisar PR duplicados o solapados antes de crear otros.
- Describir objetivo, alcance, archivos, pruebas, limitaciones y notas de reversión relevantes.
- No fusionar ni desplegar sin autorización explícita, aunque los checks estén verdes.

## 8. Coordinación de agentes
- **Coordinación:** mantiene alcance, dependencias, estado y ausencia de conflictos.
- **Implementación:** realiza un cambio acotado y añade pruebas.
- **QA:** revisa diff y evidencia de forma independiente.
- **Seguridad/privacidad:** revisa permisos, datos, sesiones, entradas y secretos.
- **Documentación:** modifica solo instrucciones afectadas.

Cada tarea delegada debe especificar objetivo, resultado, archivos permitidos/prohibidos, pruebas, restricciones y formato de entrega. La cantidad de agentes no prueba que exista paralelismo real: comprobar sus resultados y evidencias.

## 9. Priorización
Priorizar bloqueos de compilación, autenticación, integridad de datos y flujos principales del MVP sobre funciones nuevas o retoques cosméticos. Respetar el orden de trabajo vigente; una función en la hoja de ruta no está terminada hasta que el repositorio y las pruebas lo demuestren.

Los módulos contemplados incluyen autenticación, perfil, glucosa, insulina, panel, nutrición, actividad, sincronización, seguridad, QR Médico, SOS y AI Guardian, solo dentro del alcance ya aprobado.

## 10. Definition of Done
Un bloque está completo cuando:
- Cumple los criterios de aceptación y mantiene la arquitectura v2.7.
- El diff final fue revisado y no incluye cambios ajenos ni secretos.
- Las pruebas relevantes se ejecutaron y sus resultados son transparentes.
- Los fallos, riesgos, bloqueos y pruebas no ejecutadas están documentados.
- La documentación se actualizó si el comportamiento o la configuración cambiaron.
- El PR está listo para revisión humana; no se ha fusionado ni desplegado sin autorización.

## 11. Formato de entrega
Usar un informe conciso:
- **Objetivo**
- **Cambios realizados**
- **Pruebas y resultados**
- **Riesgos/limitaciones**
- **Rama, commit o PR** (solo si están verificados)
- **Siguiente acción concreta**

**Principio operativo:** cambios pequeños, pruebas reales, seguridad médica primero, coste mínimo y progreso demostrable.

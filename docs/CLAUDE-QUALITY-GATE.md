# DIABETA — instrucciones compactas para Claude (quality gate)

Trabaja SIEMPRE sobre la rama `codex/integracion-samsung-flutter-api` y el código existente. No reinicies ni sustituyas módulos funcionales. No incluyas relojes.

## Regla obligatoria
No declares una tarea terminada hasta implementar, ejecutar y revisar las pruebas. No inventes resultados. Si no puedes ejecutar una prueba, marca `NO VERIFICADA` y explica el comando exacto.

## Antes de editar
1. Lee el módulo afectado y sus dependencias.
2. Comprueba el estado de Git y conserva cambios ajenos.
3. Define el cambio mínimo y criterios de aceptación.

## Después de editar
Ejecuta desde la raíz:

```bash
cd apps/api && npm ci && npx prisma validate && npm run build && npm test
cd ../../apps/mobile && flutter pub get && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build apk --debug
```

Si una carpeta `test` no existe o un comando no está configurado, no lo ocultes: informa y añade pruebas apropiadas dentro del alcance.

## Autocorrección limitada
- Si falla una prueba: reproduce el error, identifica causa raíz y aplica el parche mínimo.
- Repite el conjunto relevante después del arreglo.
- Máximo 3 intentos por fallo; después detente con diagnóstico reproducible.
- Usa timeouts en pruebas de red/procesos. Nunca esperes indefinidamente ni desactives una prueba para conseguir un PASS.

## Seguridad y calidad
- No registres tokens, contraseñas, datos médicos ni secretos.
- No uses datos clínicos reales en pruebas; usa fixtures ficticios.
- No cambies dosis, umbrales clínicos ni lógica médica sin validación explícita de requisitos y revisión especializada.
- Comprueba autorización por usuario, validación de entradas, errores de red, estados de carga/vacíos y regresiones.
- No afirmes que sensores sincronizan realmente sin API/SDK y credenciales autorizadas.
- No hagas merge, despliegue ni publiques secretos.

## Informe obligatorio
Devuelve solo:
- Archivos modificados.
- Comandos ejecutados y resultado PASS/FAIL/NO VERIFICADA.
- Errores encontrados y correcciones.
- Riesgos o limitaciones restantes.
- SHA del commit, si lo creaste.

Un PASS significa únicamente que pasaron las pruebas ejecutadas; no demuestra ausencia absoluta de defectos.

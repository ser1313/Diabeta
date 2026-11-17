# Módulo educativo: uso y registro de glucómetros

## Por qué este módulo
Investigación de interés de la audiencia con NexLev (consultada el 16-11-2026).
**Estas métricas indican interés por el tema, no validez médica.** No se ha copiado
ningún vídeo ni texto: el contenido de la app es redacción propia y genérica.

| Dato | Valor (NexLev) |
|---|---|
| Canal | Learn Blood Sugar Testing (`UCTldRDPsDGk4uXL_dNxaF8A`) |
| Suscriptores / vistas totales / vídeos | 14.500 / 4.880.880 / 63 |
| Último vídeo | hace ~10 meses |
| Vistas mensuales estimadas / outlier | 138.322 / 2,85 (dato de la issue #58; no reconsultado) |

Vídeos más vistos del canal (temas):

| Tema | Ejemplo | Vistas |
|---|---|---|
| Configuración y uso | ACCU-CHEK Active | 720.000 |
| Configuración y uso | FreeStyle Lite | 347.000 |
| Configuración y uso | ONETOUCH Ultra 2 | 336.000 |
| Códigos de error | ACCU-CHEK Instant Error Codes | 185.000 |
| Pilas, fecha y hora | Accu-Chek Active battery / date | 148.000 |
| Dispositivo de punción | TRUEdraw lancing device | 114.000 |
| Solución de control | Metene control solution | 58.000 |

De ahí salen las secciones de la app: preparación, configuración (fecha/hora/pilas),
punción, solución de control, códigos de error, registro en Diabeta y cuándo pedir ayuda.

## Límites de seguridad
- Sin dosis, umbrales de glucosa ni pautas de tratamiento: `validateEducationModule`
  lo comprueba y la pantalla muestra un error seguro si el contenido no lo cumple.
- Todo el contenido está marcado `pendingClinicalReview` y la pantalla lo indica.
- Antes de publicar: revisión por un profesional sanitario con fuentes oficiales
  (manuales de fabricante y fuentes sanitarias españolas) y cambio a `clinicallyReviewed`.

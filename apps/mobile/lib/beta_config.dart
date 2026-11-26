/// Interruptores de compilación (`--dart-define`). Todos desactivados por defecto.
library;

/// Calculadora de bolo. Deshabilitada hasta su revisión profesional (issue #52).
const bool clinicalCalculatorEnabled = bool.fromEnvironment('DIABETA_CLINICAL_CALCULATOR');

/// Compilación beta de pruebas: muestra un distintivo «BETA» en toda la app.
const bool isBetaBuild = bool.fromEnvironment('DIABETA_BETA');

/// Por debajo de este valor (mg/dL) no se muestra ninguna dosis. Debe coincidir
/// con HYPOGLYCEMIA_THRESHOLD_MG_DL de la API.
const double hypoglycemiaThresholdMgDl = 70;

# Compilar Diabeta para el simulador de iOS

La CI de iOS compila la app en macOS con Flutter 3.29.0 y Xcode para el
simulador. Usa una URL HTTPS reservada y no necesita cuentas, certificados ni
secrets. El resultado de la CI confirma la compilación, no la ejecución en iOS.

Para ejecutarla en un simulador con Xcode y CocoaPods instalados, abre Simulator
y especifica la URL HTTPS de una API de pruebas con datos ficticios:

```bash
cd apps/mobile
flutter pub get
flutter devices
flutter run -d "<ID-del-simulador>" --dart-define=API_URL="<URL-HTTPS-de-pruebas>"
```

Comprueba el inicio de sesión y que la sesión de prueba se conserva al cerrar
y volver a abrir la app. El objetivo Runner usa los permisos de Keychain para
guardar el token localmente.

El identificador `com.example.diabeta` es provisional para desarrollo. Para una
prueba en un iPhone o una distribución posterior se necesita un identificador
propio registrado por el equipo de Apple Developer, su firma correspondiente
y una prueba en el dispositivo.

{{flutter_js}}
{{flutter_build_config}}

if (window.isSecureContext) {
  _flutter.loader.load({
    config: {
      canvasKitBaseUrl: "canvaskit/",
      // Roboto se sirve desde la ruta que espera el motor de Flutter 3.29.
      fontFallbackBaseUrl: "fonts/",
    },
  });
} else {
  document.getElementById("secure-context-message").hidden = false;
}

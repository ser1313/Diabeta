# Diabeta Security and Production Checklist

## Before production
- Set a long random JWT_SECRET; never use the development fallback.
- Set an explicit HTTPS CORS_ORIGIN.
- Run PostgreSQL with private networking and managed backups.
- Terminate TLS at the reverse proxy or load balancer.
- Store vendor sensor credentials only in server-side secrets.
- Never place Dexcom or Libre credentials in the Flutter application.
- Review medical-card fields before exposing a public QR endpoint.
- Do not send insulin dosing instructions from the AI Guardian.
- Add monitoring for authentication failures, API errors and synchronization failures.
- Test database restore procedures.

## Medical safety boundary
Diabeta is a support and information product. Metrics such as estimated HbA1c, TIR and Guardian warnings are informational. Any insulin calculation must use parameters supplied by the user's prescribed plan and must not silently invent clinical defaults.

## Sensor integrations
The provider adapter accepts FreeStyle Libre and Dexcom identifiers and statuses. Production synchronization must use the manufacturer's authorized API or SDK and credentials, with explicit user consent and token storage on the server.

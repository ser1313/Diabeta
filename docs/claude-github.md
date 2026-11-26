# Pedir tareas a Claude desde GitHub (`@claude`)

Workflow: `.github/workflows/claude.yml` (Claude Code GitHub Action v1.0.275, fijada por SHA).

## Quién puede activarlo
Un comentario, revisión o issue nueva que contenga `@claude`, escrito por:
- `ser1313` (propietario);
- `chatgpt-codex-connector[bot]` (Codex/ChatGPT).

Cualquier otro autor se ignora antes de arrancar. Además, **cada ejecución espera tu
aprobación** en el entorno `claude`: GitHub muestra *Review deployments* en la
ejecución y no hace nada hasta que apruebas.

Motivo: la acción no comprueba los permisos de los bots que se permiten, y el
repositorio es público. Un texto malicioso podría llegar a un comentario del bot de
Codex; la aprobación manual evita que eso active a Claude sin que lo veas.

## Configuración (una vez, la hace el propietario)
1. Instala la app de Claude para GitHub en `ser1313/Diabeta`:
   <https://github.com/apps/claude> (*Only select repositories*).
2. Genera la credencial en tu PC con `claude setup-token`, si usas la suscripción
   Pro/Max (no la pegues en chats ni issues). Como alternativa, usa una clave de API
   de Anthropic.
3. **Settings → Environments → New environment** → `claude`:
   - *Required reviewers*: `ser1313`.
   - *Deployment branches and tags*: *Selected branches* → `main`.
   - *Environment secrets*: `CLAUDE_CODE_OAUTH_TOKEN` = la credencial del paso 2.
     Si usas una clave de API, crea `ANTHROPIC_API_KEY` y cambia en el workflow
     `claude_code_oauth_token` por `anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}`.
   - No crees el secreto a nivel de repositorio.
4. Fusiona la PR del workflow. GitHub ejecuta los workflows de comentarios desde
   `main`, así que antes de fusionar no se puede probar.

## Uso
- En una issue o PR: `@claude <tarea concreta>`. Aprueba la ejecución en
  *Actions → Claude Code → Review deployments*.
- Claude trabaja en una rama `claude/...` y responde en la issue o PR.

## Límites configurados
- No puede ejecutar `gh pr merge`, `gh release`, `gh secret`, `gh variable`,
  `gh workflow`, `gh repo` ni `git push --force`, ni hacer push directo a `main`.
- Debe seguir `SECURITY.md`, mantener la calculadora deshabilitada (#52), usar solo
  datos ficticios y abrir PR en borrador sin fusionar.
- Máximo de 40 turnos por ejecución y 60 minutos por job.
- La lista de comandos bloqueados no es un *sandbox*: la protección real es la
  aprobación manual y que la credencial solo exista en el entorno `claude`.

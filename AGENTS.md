# Diabeta — Agent Operating Rules

## Mission and frozen architecture
- Continue from the official v2.7 freeze and Development 1.0 Fast Track. Do not reopen planning or redesign approved modules unless Sergio explicitly requests it.
- Preserve the architecture already present in this repository: Flutter mobile app under `apps/mobile`; NestJS/TypeScript API under `apps/api`; Prisma and PostgreSQL; Docker Compose; GitHub Actions CI.
- Treat the checked-in code and tests as the source of truth for implementation details. Do not silently migrate frameworks or introduce a second architecture.

## Work protocol
1. Inspect the relevant code, tests, package scripts, and current branch before editing.
2. Work in a dedicated feature/fix branch. Never commit directly to `main`.
3. Make the smallest coherent change that addresses the task. Avoid unrelated refactors and dependency upgrades.
4. Add or update tests for behavior changes. Run the narrowest relevant checks, then the available project checks.
5. Open a pull request with: purpose, scope, files changed, tests run, known limitations, and rollback notes where relevant.
6. Never merge a pull request, enable auto-merge, deploy, or change repository security settings without explicit human authorization.
7. If a check fails, inspect the failure logs and fix the root cause; do not report success based only on code review.

## Current checks
- API: from `apps/api`, run `npm install`, `npx prisma validate`, `npx prisma generate`, and `npm run build`.
- Mobile: from `apps/mobile`, run `flutter pub get`, `flutter analyze`, and `flutter build apk --debug`.
- GitHub Actions in `.github/workflows/ci.yml` is the authoritative CI gate. Report actual results and do not claim checks were run if they were not.

## Medical safety and privacy — mandatory
- Diabeta is an informational support application and does not replace qualified clinical care.
- Do not create features that autonomously calculate, prescribe, recommend, or change insulin doses. Do not invent clinical defaults or treatment parameters.
- Keep AI Guardian output informational, explain uncertainty, and do not present it as diagnosis or emergency monitoring.
- Treat glucose, insulin, profile, QR medical-card, and sensor data as sensitive health data. Minimize collection and exposure; enforce authorization and validate inputs.
- Never commit credentials, tokens, real patient data, production exports, or secrets. Do not place manufacturer sensor credentials in the mobile app.
- Sensor synchronization must use manufacturer-authorized APIs/SDKs and explicit consent. Never fake a successful connection or invent vendor credentials.
- SOS must not imply that emergency services have been contacted unless the device actually completes the relevant action.

## Agent collaboration
- Programmer agent: implements one bounded task and adds tests.
- Test/QA agent: independently reviews the diff and CI output; identifies missing edge cases.
- Security/privacy agent: checks authentication, authorization, data exposure, dependency risks, and secret handling.
- Documentation agent: updates only documentation affected by the change.
- Coordinator: prevents overlapping edits, checks that architecture remains frozen, summarizes evidence, and prepares the PR.
- Parallelize only independent tasks. A reviewer must not simply repeat the implementer's claims; inspect the diff and test evidence.

## Definition of done
- Scope matches the issue.
- Tests and relevant CI checks pass, or failures are clearly reported with evidence.
- No secrets or sensitive patient data are introduced.
- Medical safety boundaries are preserved.
- A human-reviewable PR is ready; merge remains a human decision.

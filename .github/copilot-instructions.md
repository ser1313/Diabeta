# GitHub Copilot instructions for Diabeta

Read and follow the repository-wide rules in `/AGENTS.md` before making changes.

Key constraints:
- Preserve the frozen v2.7 / Development 1.0 Fast Track architecture: Flutter mobile (`apps/mobile`), NestJS TypeScript API (`apps/api`), Prisma, PostgreSQL, Docker Compose, and GitHub Actions.
- Do not redesign approved modules, migrate frameworks, or perform unrelated refactors without explicit authorization.
- Work in a feature branch and propose changes through a pull request; never merge or deploy autonomously.
- Add/update tests for behavior changes and report actual command/CI results.
- Treat all health data as sensitive. Never add autonomous insulin dosing, invented clinical defaults, fake sensor integrations, or claims that SOS contacted emergency services without confirmation.
- Never commit secrets, tokens, production data, or vendor credentials. Sensor integrations require authorized vendor APIs/SDKs and user consent.
- Keep changes small, reviewable, and consistent with existing patterns. Explain uncertainty and blockers rather than guessing.

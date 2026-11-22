# Diabeta agent team and automation model

This document defines how coding agents collaborate on the existing Diabeta repository. It does not change the product architecture.

## Roles
| Role | Responsibility | Output |
|---|---|---|
| Coordinator | Break down tasks, prevent overlapping work, track dependencies | Small task plan and final summary |
| Programmer | Implement one bounded change | Branch/commit and tests |
| QA reviewer | Inspect diffs and run relevant checks independently | Test evidence and findings |
| Security/privacy reviewer | Review auth, access control, health-data exposure, dependencies, and secrets | Findings prioritized by risk |
| Documentation reviewer | Update affected technical docs and setup steps | Documentation changes |

One agent may perform multiple roles for a small task, but implementation and review must remain distinct passes. Do not create extra agents when tasks overlap or provide no independent value.

## Standard workflow
1. Select one small task and record acceptance criteria.
2. Create a branch from the current intended base.
3. Inspect existing patterns and implement the smallest safe patch.
4. Add or update tests.
5. Run relevant checks locally when an execution environment is available.
6. Open a pull request and wait for GitHub Actions.
7. Review the diff, CI logs, security implications, and medical-safety constraints.
8. Merge only after explicit human approval and required checks are green.

## Automation gates
- Safe to automate: issue/task drafts, branch creation, code suggestions, formatting, static analysis, builds, tests, dependency alerts, documentation drafts, and CI summaries.
- Require review: authentication changes, authorization, database migrations, health-data retention/export, QR-card visibility, SOS behavior, sensor integrations, AI Guardian behavior, and any clinical content.
- Never automate without explicit approval: merging to `main`, production deployment, rotating/revoking credentials, changing repository permissions, or releasing a medical feature.

## CI and evidence
The existing workflow `.github/workflows/ci.yml` validates the API (Prisma validation/generation and Nest build) and mobile app (Flutter analyze and debug APK build). CI status is the source of truth for remote checks. Agents must cite the actual run or log and must not claim a pass when a job is pending, skipped, or failed.

## Current first milestone
Bootstrap shared agent instructions without changing application code or dependencies. Confirm the instructions are present on the PR branch and that the existing API/mobile CI jobs complete. Once this baseline is merged, use the same workflow to address the known API build failure in the separate JSON body-size-limit PR.

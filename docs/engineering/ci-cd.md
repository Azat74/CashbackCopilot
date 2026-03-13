# CI/CD

## Scope

Репозиторий покрывает только iOS client.

## Current pipelines

- `ios-ci.yml` — генерация проекта, build, unit tests, optional lint
- `security-checks.yml` — secret scanning
- `no-generated-artifacts.yml` — защита от случайного коммита build artifacts
- `business-guardrails.yml` — запуск guardrail tests
- `decision-logic-regression.yml` — запуск regression cases для recommendation engine
- `release.yml` — archive build и artifact upload

## Out of scope

- backend deploy
- server security scanning
- infra provisioning
- App Store auto-publish


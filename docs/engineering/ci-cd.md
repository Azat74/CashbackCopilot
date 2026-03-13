# CI/CD

## Scope

Репозиторий покрывает только iOS client.

## Current pipelines

- `ios-ci.yml` — генерация проекта, build, unit tests, optional lint
- `ui-smoke.yml` — отдельный smoke scenario для onboarding -> manual recommendation -> payment log
- `security-checks.yml` — secret scanning
- `no-generated-artifacts.yml` — защита от случайного коммита build artifacts
- `business-guardrails.yml` — запуск guardrail tests
- `decision-logic-regression.yml` — запуск regression cases для recommendation engine
- `release.yml` — archive build и artifact upload

## Current policy

- на каждый PR обязательно проходят build, unit tests, business guardrails и regression checks
- UI smoke tests вынесены в отдельный workflow и запускаются отдельно от основного `ios-ci`
- smoke сейчас проверяет два сценария:
  - onboarding -> manual recommendation -> log payment
  - onboarding -> QR scanner shell -> payload parse
- каждый smoke scenario запускается отдельным `xcodebuild`, чтобы снизить flake rate на GitHub-hosted macOS runners
- `ui-smoke` добавлен в required status checks для `main` ruleset
- это значит, что merge в `main` теперь блокируется, если smoke scenario не прошел на PR
- workflow по-прежнему не заменяет основной unit/build CI, а дополняет его отдельной UI-проверкой

## Out of scope

- backend deploy
- server security scanning
- infra provisioning
- App Store auto-publish

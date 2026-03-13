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
- smoke сейчас проверяет один сценарий: onboarding -> manual recommendation -> log payment
- workflow нужен для раннего detection UI regressions, но пока не считается обязательной заменой основного unit/build CI
- если симуляторный прогон останется стабильным, позже можно решить, делать ли его required status check

## Out of scope

- backend deploy
- server security scanning
- infra provisioning
- App Store auto-publish

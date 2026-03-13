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

## Current policy

- на каждый PR обязательно проходят build, unit tests, business guardrails и regression checks
- UI tests пока не входят в обязательный дефолтный pipeline
- причина: для раннего MVP важнее быстрый и стабильный CI, чем шумные падения симулятора
- UI smoke tests будут вынесены в отдельный workflow после добавления `accessibilityIdentifier` на ключевые сценарии
- после стабилизации решим, запускать их на каждый PR или только на `main`

## Out of scope

- backend deploy
- server security scanning
- infra provisioning
- App Store auto-publish

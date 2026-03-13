# Cashback Copilot

`Cashback Copilot` — iOS-приложение, которое помогает выбрать самый выгодный способ оплаты перед покупкой с учетом категорий кешбека, лимитов и ограничений по каналу оплаты.

## Что уже зафиксировано

- iOS-only MVP
- SwiftUI + XcodeGen
- local-first архитектура
- без backend, auth и банковских интеграций
- рекомендации объяснимые, а не “магические”
- privacy/security guardrails встроены в репозиторий

## Базовые команды

```bash
make generate
make build
make test
make lint
```

## Важный bootstrap

Для локальной сборки нужен полный Xcode и принятая лицензия Apple SDK.

Если лицензия еще не принята, выполни один раз:

```bash
sudo --preserve-env=DEVELOPER_DIR xcodebuild -license
```

## Структура

- `project.yml` — источник истины для Xcode проекта
- `App/`, `Core/`, `Features/`, `Shared/` — код приложения
- `CashbackCopilotTests/`, `CashbackCopilotUITests/` — тесты
- `docs/` — продуктовая, архитектурная, security и QA документация
- `.github/` — workflow’ы и шаблоны ревью

## Как ведем разработку

- работаем story-by-story через ветки `codex/...`
- каждая story идет в отдельный PR
- merge в `main` только после зеленых checks
- актуальный backlog лежит в `docs/engineering/github-project-backlog.md`

## Принципы

- рекомендация, а не гарантия начисления кешбека
- `QR != MCC truth`
- неопределенность должна быть видна пользователю
- никаких банковских логинов, паролей и токенов
- минимум зависимостей и минимум разрешений

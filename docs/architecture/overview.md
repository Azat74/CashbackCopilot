# Architecture Overview

## Summary

`Cashback Copilot` — iOS-first, offline-first SwiftUI приложение. Данные пользователя хранятся локально, recommendation engine работает на устройстве, а QR и screenshot import используются как источники подсказок, а не истины.

## High-level flow

1. В начале месяца пользователь вручную настраивает правила или импортирует их по скриншотам банковского приложения.
2. Screenshot import pipeline строит локальный `ParsedCashbackDraft`, который пользователь валидирует перед сохранением.
3. Подтвержденный draft сохраняется как актуальный месячный набор правил.
4. Перед оплатой пользователь вводит сумму вручную или сканирует QR.
5. Приложение строит `PurchaseContext`.
6. Локальный `RecommendationEngine` фильтрует правила, применяет ограничения и ранжирует варианты.
7. Пользователь получает объяснимую рекомендацию.
8. После оплаты `ProgressService` обновляет локальный прогресс лимитов и историю.

## Layers

- `App` — lifecycle и root navigation
- `Features` — user-facing flows
- `Core/Import` — OCR, parsing, draft building and validation for screenshot import
- `Core/Models` — platform-agnostic domain model
- `Core/Services` — engine, parsing, progress logic
- `Core/Repositories` — contracts and adapters over persistence
- `Shared` — reusable components, previews, mock data

## Constraints

- no backend
- no auth
- no bank integrations
- no external analytics
- only local persistence

Screenshot import design details: `docs/architecture/screenshot-import-engine.md`

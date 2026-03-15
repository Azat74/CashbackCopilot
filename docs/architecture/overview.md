# Architecture Overview

## Summary

`Cashback Copilot` — iOS-first, offline-first SwiftUI приложение. Данные пользователя хранятся локально, recommendation engine работает на устройстве, а QR и screenshot import используются как источники подсказок, а не истины.

## High-level flow

1. В начале месяца пользователь вручную настраивает правила или импортирует их по скриншотам банковского приложения.
2. Screenshot import pipeline строит локальный `ParsedCashbackDraft`, который пользователь валидирует перед сохранением.
3. Подтвержденный draft сохраняется как актуальный месячный набор правил.
4. На домашнем экране пользователь выбирает quick category, recent intent или QR flow.
5. Приложение строит `PurchaseContext`.
6. Локальный `RecommendationEngine` фильтрует правила, применяет ограничения и ранжирует варианты.
7. Пользователь получает объяснимую рекомендацию за минимальное число действий.
8. После оплаты `ProgressService` обновляет локальный прогресс лимитов и историю.
9. Для ускорения базовых сценариев приложение может показывать `QuickRecommendationSnapshot` для типовых категорий.

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

## MVP priorities

- product entry should start from purchase intent, not wallet administration
- recommendation must remain useful even without amount or merchant name
- screenshot import is part of MVP onboarding, not a side tool
- recent intents and quick snapshots are acceleration layers over the same core engine

Screenshot import design details: `docs/architecture/screenshot-import-engine.md`

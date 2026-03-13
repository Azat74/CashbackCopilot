# Architecture Overview

## Summary

`Cashback Copilot` — iOS-first, offline-first SwiftUI приложение. Данные пользователя хранятся локально, recommendation engine работает на устройстве, а QR используется как источник подсказок, а не истины.

## High-level flow

1. Пользователь вводит сумму вручную или сканирует QR.
2. Приложение строит `PurchaseContext`.
3. Локальный `RecommendationEngine` фильтрует правила, применяет ограничения и ранжирует варианты.
4. Пользователь получает объяснимую рекомендацию.
5. После оплаты `ProgressService` обновляет локальный прогресс лимитов и историю.

## Layers

- `App` — lifecycle и root navigation
- `Features` — user-facing flows
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


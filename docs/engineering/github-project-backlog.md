# GitHub Project Backlog

Этот файл — живой backlog проекта. Здесь фиксируется:

- что уже закрыто в `main`
- что в работе следующими story
- что пока отложено

Формат работы:

- одна story = одна ветка `codex/...`
- после реализации создается PR
- merge в `main` только после зеленых checks

## Done

- [x] инициализация XcodeGen проекта
- [x] docs baseline
- [x] ADR baseline
- [x] CI workflows
- [x] unit test target
- [x] базовый UI test target
- [x] Bank model
- [x] PaymentMethod model
- [x] CashbackRule model
- [x] SpendProgress model
- [x] PurchaseContext model
- [x] RecommendationResult model
- [x] LoggedPayment model
- [x] recommendation filtering
- [x] cap handling
- [x] confidence scoring
- [x] reasons and risks
- [x] regression fixtures
- [x] onboarding shell
- [x] wallet CRUD
- [x] rule editor
- [x] QR scanner shell
- [x] history shell
- [x] accessibility identifiers to key screens
- [x] first stable UI smoke test for manual recommendation flow
- [x] separate UI smoke workflow in GitHub Actions
- [x] ui-smoke added as required status check for `main`
- [x] second UI smoke scenario for QR scanner shell
- [x] confirm purchase context screen after QR flow
- [x] scanner -> confirm -> recommendation flow
- [x] richer confirm context warnings and heuristics
- [x] confirm actual cashback flow
- [x] monthly cashback snapshot model
- [x] compact iPhone flow stabilization for QR and history review

## Next Stories

- [ ] screenshot import shell and photo picker
- [ ] local screenshot OCR pipeline
- [ ] parsed cashback draft review and save flow
- [ ] raw special conditions and confidence markers in import draft
- [ ] quick recommendation snapshots on the home screen
- [ ] recent purchase intents on the home screen

## Testing and Automation

- [x] decide whether UI smoke runs on every PR or only on `main`
- [x] expand UI smoke beyond shell QR flow into confirmed purchase context
- [x] add separate QR-driven smoke path through payment logging

## Later

- [ ] screenshot import bank-specific heuristics
- [ ] QR parsing improvements
- [ ] bank templates/presets
- [ ] import/export
- [ ] app lock / privacy hardening
- [ ] widget / shortcut quick launch for recommendation
- [ ] smart quick hints for common categories
- [ ] shareable cashback card
- [ ] favorite merchants
- [ ] context suggestions from repeated scenarios
- [ ] privacy-safe collective cashback knowledge

## MVP Priority Map

### P0 — продукт должен уметь это для v1

- [x] recommendation engine
- [x] purchase-first UI
- [x] quick categories
- [x] recommendation screen
- [x] optional amount input
- [x] cashback rule storage
- [ ] screenshot cashback import

### P1 — сильно повышает удобство

- [ ] quick recommendation snapshots
- [ ] recent purchase intents
- [x] QR payment flow
- [x] explanation UI

### P2 — ускорение и быстрый доступ

- [ ] widget / shortcut quick launch for recommendation
- [ ] smart quick hints for common categories
- [x] confidence scoring in recommendation flow
- [ ] confidence markers in screenshot import draft

### P3 — growth / secondary surfaces

- [x] history
- [ ] shareable cashback card
- [ ] favorite merchants
- [ ] context suggestions from repeated scenarios

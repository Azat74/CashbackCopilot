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

## Next Stories

- [ ] monthly cashback snapshot model
- [ ] screenshot import shell and photo picker
- [ ] local screenshot OCR pipeline
- [ ] parsed cashback draft review and save flow
- [ ] raw special conditions and confidence markers in import draft

## Testing and Automation

- [x] decide whether UI smoke runs on every PR or only on `main`
- [x] expand UI smoke beyond shell QR flow into confirmed purchase context
- [x] add separate QR-driven smoke path through payment logging

## Later

- [ ] QR parsing improvements
- [ ] bank templates/presets
- [ ] import/export
- [ ] app lock / privacy hardening
- [ ] bank-specific screenshot import heuristics
- [ ] widget / shortcut quick launch for recommendation
- [ ] privacy-safe collective cashback knowledge

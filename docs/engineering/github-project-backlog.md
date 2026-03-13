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

## Next Stories

- [ ] manual recommendation flow polish
- [ ] payment logging from recommendation result
- [ ] home form validation and empty/error states
- [ ] history details for expected vs actual cashback
- [ ] confirm purchase context screen after QR flow
- [ ] settings cleanup and local data reset UX

## Testing and Automation

- [ ] add accessibility identifiers to key screens
- [ ] add first stable UI smoke test for manual recommendation flow
- [ ] move UI smoke checks into a separate workflow
- [ ] decide whether UI smoke runs on every PR or only on `main`

## Later

- [ ] QR parsing improvements
- [ ] confirm actual cashback flow
- [ ] bank templates/presets
- [ ] import/export
- [ ] app lock / privacy hardening

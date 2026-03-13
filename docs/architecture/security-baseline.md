# Security Baseline

## Принципы

- data minimization first
- offline-first by default
- no banking credentials ever
- least permissions
- minimal third-party SDK usage
- no secrets in client code
- privacy-safe analytics only

## Разрешено в v1

- локальное хранение правил, лимитов и истории
- QR parsing на устройстве
- локальный recommendation engine

## Запрещено в v1

- хранение логинов/паролей банков
- хранение полного номера карты и CVV/CVC
- отправка raw QR payload во внешние сервисы
- embedding privileged secrets in app code
- сетевые запросы без документированного обоснования

## Storage guidance

- SwiftData — для локального состояния приложения
- UserDefaults — только для мелких UI preferences
- Keychain — только если позже появятся реальные локальные секреты


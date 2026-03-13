# Data Model

## Core entities

### Bank

Финансовая организация в кошельке пользователя.

### PaymentMethod

Конкретный способ оплаты: дебетовая карта, кредитная карта, SBP или QR-specific канал.

### CashbackRule

Правило выгоды, привязанное к способу оплаты: категория, процент или фиксированный reward, лимиты, разрешенные каналы.

### SpendProgress

Текущий прогресс использования лимитов по конкретному правилу и периоду.

### PurchaseContext

Контекст покупки перед оплатой: сумма, категория, merchant hint, source, channel, confidence.

### RecommendationOption

Один кандидат на оплату с расчетом expected reward, confidence, reasons и risks.

### RecommendationResult

Итоговая рекомендация: лучший вариант и список альтернатив.

### LoggedPayment

Локально зафиксированный факт оплаты и сравнение expected vs actual.

## Modeling rules

- domain entities остаются независимыми от SwiftUI и SwiftData
- payment channel хранится как first-class признак
- caps обрабатываются отдельно от правил через `SpendProgress`
- raw QR payload по умолчанию не является постоянной частью доменной модели


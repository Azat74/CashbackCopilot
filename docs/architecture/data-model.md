# Data Model

## Core entities

### Bank

Финансовая организация в кошельке пользователя.

### PaymentMethod

Конкретный способ оплаты: дебетовая карта, кредитная карта, SBP или QR-specific канал.

### CashbackRule

Правило выгоды, привязанное к способу оплаты: категория, процент или фиксированный reward, лимиты, разрешенные каналы.

### CashbackMonth

Месячный снимок категорий и ограничений для конкретного банка. Recommendation engine должен работать с актуальным набором правил месяца, а не со смешанным набором исторических правил.

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

### ParsedCashbackDraft

Черновик месячного набора правил, полученный после screenshot import. Содержит список распознанных правил, количество исходных скриншотов, confidence и признаки того, что требуется ручная проверка.

### ParsedRuleDraft

Черновик одного правила из screenshot import: category name, reward fields, raw conditions, ограничения по каналу оплаты и confidence per field.

## Modeling rules

- domain entities остаются независимыми от SwiftUI и SwiftData
- payment channel хранится как first-class признак
- caps обрабатываются отдельно от правил через `SpendProgress`
- raw QR payload по умолчанию не является постоянной частью доменной модели
- OCR и parser не должны напрямую создавать `CashbackRule` без шага user review
- raw text особых условий хранится отдельно от структурированных полей, если parser не уверен в их значении
- monthly snapshot должен быть first-class сущностью, а не неявным фильтром по дате

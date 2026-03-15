# Screenshot Import Engine

## Goal

Сделать ежемесячное обновление кешбек-категорий быстрым и реалистичным: пользователь прикладывает скриншоты из банковского приложения, а `Cashback Copilot` локально создает проверяемый draft вместо ручного ввода правил с нуля.

## Product flow

1. Пользователь выбирает банк.
2. Нажимает `Импортировать из скриншотов`.
3. Прикладывает один или несколько скриншотов:
   - основной экран категорий
   - дополнительные hint / tooltip экраны с условиями
4. Приложение локально извлекает текст и строит `ParsedCashbackDraft`.
5. Пользователь видит draft с confidence markers и raw conditions.
6. Пользователь исправляет спорные места и сохраняет результат как правила текущего или нового месяца.

## Non-goals

- не обещаем идеальное распознавание банковских условий
- не логинимся в банк и не используем банковские credentials
- не отправляем скриншоты на backend в MVP
- не создаем `CashbackRule` silently без подтверждения пользователя

## Pipeline

`Screenshots -> OCRService -> OCRTextBlock[] -> CashbackParser -> ParsedRuleDraft[] -> ImportDraftBuilder -> ParsedCashbackDraft -> User Review -> CashbackMonth`

## Proposed modules

### `Features/Import`

- `ScreenshotImportView`
- `ImportDraftReviewView`
- `ImportRuleEditorView`

### `Core/Import`

- `ScreenshotImportService`
- `OCRService`
- `CashbackParser`
- `ImportDraftBuilder`
- `ImportValidator`

## Proposed models

```swift
struct OCRTextBlock {
    let text: String
    let boundingBox: CGRect
}

struct ParsedRuleDraft: Identifiable, Codable {
    let id: UUID
    var categoryName: String
    var percent: Double?
    var fixedReward: Double?
    var limitText: String?
    var specialConditionsText: String?
    var qrAllowed: Bool?
    var sbpAllowed: Bool?
    var confidence: Double
    var needsReview: Bool
}

struct ParsedCashbackDraft: Identifiable, Codable {
    let id: UUID
    var bankName: String?
    var monthLabel: String?
    var rules: [ParsedRuleDraft]
    var sourceScreenshotsCount: Int
    var createdAt: Date
}
```

## Parsing strategy

- OCR на устройстве через Apple frameworks
- parser сначала извлекает простые структурируемые вещи:
  - category name
  - percent
  - fixed reward
  - limit text
  - QR/SBP restrictions when obvious
- неоднозначные условия остаются в `specialConditionsText`
- при uncertainty parser снижает `confidence` и выставляет `needsReview = true`

## UX guardrails

- draft должен показывать, что распознано уверенно, а что требует проверки
- raw text особых условий не должен теряться
- пользователь всегда может удалить импортированное правило или поправить поле вручную
- save flow должен явно спрашивать, в какой месяц сохранить набор правил

## Why this matters

Главный барьер продукта не в recommendation engine, а в том, что пользователю тяжело ежемесячно заносить категории вручную. Screenshot import превращает onboarding из ручной формы в короткий review flow и делает recommendation engine жизнеспособным в повседневном использовании.

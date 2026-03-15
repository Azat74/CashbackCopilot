# Product Features

Этот документ фиксирует продуктовые фичи в порядке приоритета для MVP.

Принцип сортировки:

1. без этого продукт не работает
2. без этого продукт работает хуже
3. это заметно улучшает UX
4. это growth / social / nice-to-have

## P0 — Core MVP

### 1. Recommendation Engine

Ядро продукта, которое определяет лучший способ оплаты.

Responsibilities:

- eligibility check
- reward calculation
- cap handling
- ranking
- explanation

Input:

- `PurchaseContext`

Output:

- `RecommendationResult`

Status:

- implemented in MVP baseline

### 2. Purchase-first UI

Основной UX строится вокруг покупки, а не вокруг списка карт и таблиц кешбека.

Primary flow:

purchase -> recommendation -> payment

Status:

- implemented in MVP baseline

### 3. Quick Categories

Главный быстрый вход в продукт через типовые сценарии покупки.

Examples:

- АЗС
- Продукты
- Кафе
- Такси
- Онлайн
- QR

Status:

- implemented in MVP baseline

### 4. Recommendation Screen

Экран результата должен быстро показывать:

- лучший способ оплаты
- ожидаемый кешбек
- альтернативы
- объяснение

Status:

- implemented in MVP baseline

### 5. Optional Amount Input

Сумма улучшает расчет, но не должна быть обязательным барьером перед рекомендацией.

Status:

- implemented in MVP baseline

### 6. Cashback Rule Storage

Система хранения месячных правил кешбека, банков, способов оплаты и лимитов.

Status:

- implemented in MVP baseline

### 7. Screenshot Cashback Import

Ключевая onboarding-фича.

Flow:

1. пользователь делает скриншот экрана категорий кешбека
2. при необходимости добавляет скриншоты tooltip / hint экранов
3. приложение локально извлекает текст
4. приложение создает черновик правил
5. пользователь валидирует и сохраняет набор на месяц

Status:

- next major MVP track

## P1 — Very Important UX

### 8. Quick Recommendation Snapshots

Предвычисленные подсказки для частых категорий на домашнем экране.

Examples:

- АЗС -> Т-Банк 10%
- Продукты -> Альфа 7%

Status:

- planned

### 9. Recent Purchase Intents

Блок последних сценариев покупки для one-tap повторного выбора.

Status:

- planned

### 10. QR Payment Flow

QR-assisted сценарий:

scan QR -> detect context -> recommendation

Status:

- implemented in MVP baseline

### 11. Explanation UI

Отдельный видимый блок "почему эта карта / этот способ оплаты".

Status:

- implemented in MVP baseline

## P2 — Product Acceleration

### 12. Widget

Быстрый вход в recommendation flow с домашнего экрана.

Status:

- later

### 13. Shortcut / Action Button

Сверхбыстрый запуск recommendation flow без навигации по приложению.

Status:

- later

### 14. Smart Quick Hints

Контекстные подсказки на домашнем экране по текущим лучшим вариантам.

Status:

- later

### 15. Confidence Score

Явная оценка надежности рекомендации или импортированного поля.

Status:

- partially implemented for recommendation
- planned for screenshot import draft

## P3 — Growth / Nice-to-have

### 16. Share Cashback Card

Генерация shareable карточки с активными категориями.

Status:

- later

### 17. History

Локальная история оплат и сверка expected vs actual cashback.

Status:

- implemented, but not a primary acquisition feature

### 18. Favorite Merchants

Избранные места для более быстрого старта сценария.

Status:

- later

### 19. Context Suggestions

Подсказки на основе частых сценариев, времени и привычек.

Status:

- later

## Real MVP Cut

### Must

- Recommendation Engine
- Purchase-first UI
- Quick Categories
- Recommendation Screen
- Cashback Rule Storage
- Screenshot Cashback Import

### Should

- Quick Recommendation Snapshots
- Recent Purchase Intents

### Later

- QR deepening
- Widget / Shortcut
- Share surfaces

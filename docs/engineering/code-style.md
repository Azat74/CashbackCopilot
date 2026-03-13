# Code Style

## Общие правила

- prefer small focused types
- keep domain logic out of views
- avoid hidden fallback behavior
- validate user input at boundaries
- не использовать force unwrap в production logic без строгого обоснования

## SwiftUI

- view отвечает за presentation, а не за recommendation logic
- сложные расчеты и parsing уходят в `Core/Services`

## Документация

- non-obvious business logic комментировать коротко и по делу
- при изменении семантики модели обновлять docs


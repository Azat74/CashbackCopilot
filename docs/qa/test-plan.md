# Test Plan

## Unit tests

- reward calculation
- reward cap handling
- spend cap handling
- min amount handling
- unsupported channel filtering
- no valid option path
- confidence clamping
- reasons and risks generation

## Regression tests

- fuel purchase prefers higher reward option
- QR purchase excludes QR-disabled rule
- exhausted cap changes winner
- no matching category returns empty recommendation

## UI smoke tests

- app launch
- tab rendering
- onboarding entry
- manual recommendation happy path
- scanner fallback path

## Текущий статус

- unit tests и domain regression tests уже являются основной частью CI
- UI smoke tests пока считаются следующим этапом стабилизации
- перед их обязательным включением в pipeline нужно:
  - добавить `accessibilityIdentifier` на ключевые экраны и кнопки
  - зафиксировать один стабильный happy path
  - вынести UI smoke в отдельный workflow

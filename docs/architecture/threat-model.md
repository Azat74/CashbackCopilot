# Threat Model

## Assets

- пользовательские правила кешбека
- названия способов оплаты
- текущий прогресс лимитов
- история рекомендаций и оплат
- QR-derived purchase context

## Key threats

### 1. Локальная утечка данных

Риск: компрометированное устройство, backup extraction, shared device misuse.

Mitigation: хранить минимум данных, не хранить креды, использовать Keychain только для действительно чувствительных значений.

### 2. Reverse engineering клиента

Риск: извлечение endpoint’ов и логики из бинаря.

Mitigation: не держать секреты в клиенте и не полагаться на obscurity.

### 3. Excessive telemetry leakage

Риск: утечка merchant names, сумм или QR payload через внешние SDK.

Mitigation: не подключать analytics в MVP и не отправлять детальные финансовые payload’ы наружу.

### 4. Supply-chain risk

Риск: сторонние библиотеки вносят privacy/security проблемы.

Mitigation: предпочитать Apple frameworks и минимизировать зависимости.

### 5. Misleading certainty

Риск: пользователь верит uncertain recommendation как гарантии.

Mitigation: confidence + risks + conservative calculation.


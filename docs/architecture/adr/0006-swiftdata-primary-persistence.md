# ADR-0006: SwiftData as primary persistence for v1

## Status

Accepted

## Context

Нужна локальная persistence с минимальным boilerplate и хорошей связкой со SwiftUI.

## Decision

Для v1 использовать SwiftData, но держать business logic независимой через adapters/contracts.

## Consequences

- плюс: быстрый старт и нативная интеграция
- минус: нужен отдельный mapping слой, чтобы доменная модель не слиплась с persistence


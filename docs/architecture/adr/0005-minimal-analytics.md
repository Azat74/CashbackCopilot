# ADR-0005: Minimal analytics without raw financial payloads

## Status

Accepted

## Context

Подробная телеметрия по merchant names, raw QR и суммам противоречит privacy posture продукта.

## Decision

В MVP не добавляем внешнюю аналитику; при необходимости позже допускается только агрегированная и privacy-safe telemetry.

## Consequences

- плюс: выше доверие и меньше риск утечки
- минус: меньше удаленной диагностики edge cases


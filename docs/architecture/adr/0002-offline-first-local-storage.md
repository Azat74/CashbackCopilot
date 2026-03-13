# ADR-0002: Offline-first architecture for MVP

## Status

Accepted

## Context

Основную ценность можно проверить без сервера и без облачной синхронизации.

## Decision

Первый релиз строим как offline-first приложение с локальным хранением.

## Consequences

- плюс: меньше attack surface и быстрее разработка
- минус: нет cross-device sync и централизованных обновлений правил


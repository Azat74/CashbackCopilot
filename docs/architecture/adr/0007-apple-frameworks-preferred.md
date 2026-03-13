# ADR-0007: Apple frameworks preferred over third-party SDKs

## Status

Accepted

## Context

Сторонние SDK увеличивают supply-chain risk и усложняют privacy story.

## Decision

По умолчанию использовать Apple frameworks, а сторонние зависимости добавлять только при явном обосновании.

## Consequences

- плюс: проще audit и сопровождение
- минус: иногда меньше готовых abstractions


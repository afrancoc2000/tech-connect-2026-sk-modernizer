---
applyTo: "specs/**"
---

# Modernization Specification Instructions

When working with files under the `specs/` directory, follow these conventions:

## Specification Files

- Specifications describe **WHAT** must change in an AI application modernization — never **HOW**.
- All language must be technology-agnostic: no framework names, SDK references, API signatures, or code snippets.
- Every functional requirement must include testable acceptance criteria.
- Success criteria must be measurable from a user or business perspective.
- Specifications are authored by the `@modernmint-spec` agent.

## Quality Standards

- Maximum 3 open questions per specification.
- All assumptions must be documented explicitly.
- Scope must be clearly bounded with both in-scope and out-of-scope sections.
- User scenarios must cover all primary interaction flows.

## Workflow

1. The `@modernmint-spec` agent produces the specification at `specs/modernization-spec.md`.
2. A quality checklist is generated at `specs/checklists/spec-quality.md`.
3. Once the specification is validated, use `@modernmint-planner` to generate the technical implementation plan.
4. The planner produces phased plan files under `plans/` with a quality checklist at `plans/checklists/plan-quality.md`.

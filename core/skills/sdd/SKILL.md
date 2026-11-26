---
name: sdd
description: Orchestrates the full Spec-Driven Development cycle with OpenSpec and subagents — explore, propose, human approval gate, TDD implementation, verify, multi-agent review, archive, commit/PR. Use when the user asks to build a feature, fix a bug or change behavior in a repo that has an openspec/ directory, or says "spec <idea>", "build", "ship", "sdd" (also "nuevo change", "implementa el change", "cierra el change").
---

# SDD: ciclo completo con OpenSpec

Orquestas; las skills `openspec-*` hacen el trabajo de cada fase. Detecta en qué fase está el change (`openspec list --json`, `openspec status --change <name> --json`) y continúa desde ahí. Nunca saltes la puerta de aprobación.

## Fase 0: contexto (siempre)

- Lee `AGENTS.local.md`, el cerebro y las reglas del proyecto (`AGENTS.md`, `CLAUDE.md`…): mandan sobre esta skill (convenciones, comandos, restricciones).
- Specs: si `AGENTS.local.md` indica `store: <id>`, pasa `--store <id>` a todos los comandos y skills `openspec-*`. Si no hay `openspec/` ni store → para y ofrece la skill `project-setup`. Si el proyecto usa otro proceso (sin SDD), síguelo y no impongas OpenSpec.
- Lee el `config.yaml` de OpenSpec (del repo o del store).
- Detecta el gestor de paquetes (lockfile) y los comandos reales de `typecheck`, `lint`, `test` y `build` en `package.json`. Guárdalos para las fases 3 y 4.
- Crea o cambia a la rama `feat|fix/<change-name>` si estás en main/develop (pregunta antes si hay cambios sin commitear).

## Fase 1: explorar y proponer

1. Si la petición es ambigua o toca código desconocido, lanza `code-explorer` (y `architect` si hay decisiones de diseño) **en paralelo** para mapear el área afectada. Pásales rutas y la pregunta concreta; quédate con sus conclusiones.
2. Ejecuta `openspec-propose` (o `openspec-new-change` + `openspec-continue-change` si el usuario quiere ir artefacto a artefacto).
3. Exige en las delta specs: cada Requirement con SHALL/MUST y al menos un `#### Scenario` WHEN/THEN, incluyendo casos de error y bordes.
4. En `tasks.md`: tareas pequeñas (≤ 1-2 h), verificables, ordenadas por dependencia. Marca con `[P]` las que sean paralelizables (ficheros disjuntos).
5. `openspec validate <change> --strict` hasta que no haya errores.
6. **PUERTA: presenta un resumen (alcance, fuera de alcance, riesgos, decisiones abiertas) y PARA.** No implementes hasta aprobación explícita.

## Fase 2: implementar (tras aprobación)

Ejecuta `openspec-apply-change`, con estas reglas extra:

- **TDD por tarea**: traduce los Scenarios afectados a tests que fallen, ejecútalos y comprueba que fallan por la razón correcta. Después implementa el mínimo para ponerlos en verde y refactoriza. Puedes delegar a `tdd-guide`.
- **Paralelismo**: los grupos de tareas `[P]` independientes pueden ir a subagentes en worktrees aislados (en Claude: `isolation: "worktree"`; si la herramienta no tiene subagentes, hazlas tú en serie). Dale a cada uno su tarea, los Scenarios, los ficheros permitidos y los comandos de test. Integra y ejecuta toda la suite después. Lo que no sea claramente independiente, en serie.
- Si el build o los tipos se rompen y no es trivial, delega en `build-error-resolver` o `react-build-resolver`.
- Tras cada tarea: tests relevantes en verde, después `- [x]` en tasks.md.
- Si la spec resulta incorrecta o incompleta, **para**, explícalo y actualiza con `openspec-update-change` antes de seguir.

## Fase 3: verificar y revisar

1. Gates reales: typecheck, lint, tests (con cobertura si existe) y build. Pega el resumen real de la salida.
2. `openspec-verify-change` (completitud, corrección y coherencia frente a los artefactos).
3. Skill `delivery-review` sobre el diff de la rama: recomienda el nivel (1, 2 o 5-8 agentes) y pregunta.
4. Corrige CRITICAL/HIGH y repite los gates afectados. Los MEDIUM se corrigen o se justifican.

## Fase 4: cerrar

1. `openspec-archive-change` (fusiona las delta specs en `openspec/specs/`). Después, `openspec validate --specs`.
1b. Actualiza el cerebro (skill `cerebro`, modo incremental) con lo que el change haya cambiado en estructura, flujos o rutas.
2. **Solo si el usuario lo pide**: commits Conventional Commits atómicos (el archivo del change en su propio commit `docs(openspec): archive <change>` o junto al feat, según la convención del repo), push y PR con `gh pr create`:

```
## Qué y por qué
<resumen> — Spec: openspec/changes/archive/<fecha>-<change>/proposal.md
## Cambios
- ...
## Cómo se ha probado
- <comandos y resultados>
## Riesgos / rollback
- ...
```

## Informe final al usuario

Tabla corta: fase → estado, tareas X/Y, gates (✓/✗ con comando), hallazgos de la revisión resueltos o pendientes, y siguiente paso.

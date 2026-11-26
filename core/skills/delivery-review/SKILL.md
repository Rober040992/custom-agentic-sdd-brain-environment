---
name: delivery-review
description: Multi-agent pre-merge review of the current branch diff — runs spec-compliance, code quality, security, silent-failure, test-coverage and stack-specific reviewers in parallel, then deduplicates and ranks findings. Use before committing/opening a PR, at the end of an OpenSpec change, or when the user says "revisa la rama", "review de entrega", "delivery review".
---

# Delivery review (multiagente)

## 1. Preparar el contexto (tú, no los subagentes)

- Base: `git merge-base HEAD origin/main` (o develop si es la rama base del repo).
- `git diff --stat <base>...HEAD` y la lista de ficheros cambiados (incluye los no commiteados: `git status --porcelain`).
- Change de OpenSpec activo: `openspec list --json` → ruta a `proposal.md`, `design.md`, `tasks.md` y las delta specs.
- Si el diff tiene más de ~2000 líneas, avisa y propón revisar por módulos.

## 1b. Elegir nivel (recomienda y pregunta)

| Nivel | Agentes | Cuándo |
|---|---|---|
| **Mínimo** | 1: `code-reviewer` (incluye comprobar la spec) | Cambio pequeño (≲100 líneas, 1-3 ficheros), sin zonas sensibles |
| **Ligero** | 2: `code-reviewer` + cumplimiento de spec/tests | Cambio mediano, sin zonas sensibles |
| **Completo** | 5-8: todos los de abajo | Cambio grande o que toca zonas sensibles: auth, permisos, pagos, datos personales, BD/migraciones, APIs públicas, seguridad |

Recomienda un nivel con el motivo en una línea (p. ej. "Ligero: 60 líneas en 2 ficheros de UI, sin auth ni BD") y pregunta antes de lanzar. Si el usuario ya indicó el nivel, no preguntes. Zonas sensibles → recomienda siempre Completo.

## 2. Lanzar revisores EN PARALELO (subagentes; si la herramienta no los tiene, haz cada revisión tú en serie con el mismo foco)

Lanza solo los del nivel elegido. Para el nivel Completo, usa la lista siguiente:

Cada prompt incluye la base, la lista de ficheros, la ruta del change y este formato de salida obligatorio:
`[SEVERIDAD CRITICAL|HIGH|MEDIUM|LOW] fichero:línea — problema — escenario de fallo concreto — arreglo sugerido`. Pide solo hallazgos verificados en el código, sin estilo que ya cubra el linter.

Siempre:
- `code-reviewer`: corrección, legibilidad, convenciones del repo.
- `security-reviewer`: input del usuario, authz/authn, secretos, inyección, SSRF.
- `silent-failure-hunter`: errores tragados, fallbacks peligrosos.
- `pr-test-analyzer`: ¿los tests cubren cada `#### Scenario` de las delta specs? Lista los Scenarios sin test.
- **Cumplimiento de spec** (`general-purpose`): por cada Requirement/Scenario de las delta specs, dónde se implementa (fichero:línea) y si se cumple. Señala también comportamiento implementado que no está en la spec (scope creep).

Según los ficheros tocados:
- `.ts/.js` → `typescript-reviewer`
- `.tsx/.jsx` → `react-reviewer`
- SQL, migraciones, `schema.prisma` → `database-reviewer`

## 3. Consolidar (tú)

1. Deduplica (mismo fichero:línea y misma causa → uno, citando qué revisores coinciden).
2. **Verifica cada CRITICAL/HIGH** leyendo el código tú mismo; descarta falsos positivos y di cuántos descartaste.
3. Informe:

```
## Delivery review — <rama> vs <base>
Veredicto: ✅ listo | ⚠️ listo con reservas | ❌ bloqueado
| Sev | Fichero:línea | Problema | Arreglo | Fuente |
Cobertura de spec: N/M Scenarios con test (faltan: ...)
```

4. No apliques arreglos salvo que el usuario lo pida o vengas de la skill `sdd` (Fase 3). En ese caso arregla CRITICAL/HIGH y vuelve a ejecutar los gates.

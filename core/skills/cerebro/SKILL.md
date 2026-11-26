---
name: cerebro
description: Create, read, check and update the project's brain (.agents/brain.md) — a local, pointer-only map of what the project is, how it works and where things live, so the agent doesn't re-read the repo every session. Use when the user says "lee cerebro", "actualiza cerebro", "crea cerebro", when a session-start check reports the brain missing/outdated, or after a change alters structure, flows or conventions.
---

# Cerebro del proyecto

`.agents/brain.md`: local, oculto vía `.git/info/exclude`. Lo leen todas las herramientas (Claude lo importa desde `CLAUDE.local.md` con `@.agents/brain.md`).
**Solo punteros**: rutas, nombres y una línea de explicación. Nunca copies código ni contenido de ficheros. Máximo ~150 líneas.

## Plantilla

```markdown
# Cerebro — <proyecto>
<!-- brain: commit=<sha completo de HEAD> date=<YYYY-MM-DD> -->

## Qué es
<2-4 líneas: producto, para quién, stack principal>

## Cómo va
- Arquitectura: <capas/módulos y cómo se comunican, 3-6 líneas>
- Flujos clave: <flujo> → `ruta/entrada` → `ruta/servicio` → `ruta/persistencia>
- Comandos: dev=… test=… lint=… build=…
- Convenciones no obvias: …

## Dónde
| Concepto | Ruta |
|---|---|
| Rutas API | `src/...` |
| Modelos / schema BD | `prisma/schema.prisma` |
| Auth | `...` |
| Specs | `openspec/specs/` o store `<id>` |

## Estado
- Changes activos: …
- Trampas / deuda conocida: …
```

## Acciones

**"lee cerebro"** (manual):
1. Lee `.agents/brain.md`. Si no existe → ofrece crearlo.
2. Comprueba si está al día: `git diff --name-only <commit> HEAD` (ignora `.agents/` y `.claude/`) y `git status --porcelain`.
3. Responde en ≤5 líneas: estado (al día / N ficheros cambiados) y resumen. Si hay muchos cambios o el commit no existe → pregunta si releer el proyecto.

**Crear / releer el proyecto** (siempre con OK del usuario):
1. Mapea con un subagente explorador (`code-explorer`) si la herramienta lo permite; si no, tú mismo. Rutas, no contenido: manifiestos, entradas, módulos, BD, config.
2. Escribe la plantilla con el commit de `HEAD` y la fecha de hoy.
3. Asegura `.agents/brain.md` en `.git/info/exclude` y, si usas Claude, `@.agents/brain.md` en `CLAUDE.local.md`.

**Actualizar (incremental, sin preguntar)**: tras un change archivado o cuando toques zonas que han cambiado, edita solo las secciones afectadas y actualiza `commit=` y `date=`. Si lo que encuentras contradice el cerebro, corrígelo en el momento.

## Reglas de uso

- Antes de explorar el disco, consulta el cerebro y ve directo a las rutas que indica.
- Si una ruta del cerebro ya no existe → corrige el cerebro y avisa en una línea.
- Si el desajuste es grande (estructura distinta, más de ~60 ficheros cambiados) → pregunta: "¿Releo el proyecto para realinear el cerebro?"
- Si la herramienta no tiene comprobación automática al iniciar sesión, haz el paso 2 de "lee cerebro" al empezar a trabajar en el proyecto.

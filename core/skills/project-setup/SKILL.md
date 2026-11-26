---
name: project-setup
description: Adapt the coding agent to the current project with a private, per-project overlay (AGENTS.local.md, brain, tool-local settings, OpenSpec in-repo or in a private store) that never touches the client repo or other projects. Use when entering a new project/repo, or when the user says "setup", "prepara este proyecto", "project setup", "adapta el agente a este repo", "inicializa openspec".
---

# Project setup (capa privada por proyecto)

Objetivo: adaptar el agente al proyecto SIN dejar rastro en el repo del cliente ni afectar a otros proyectos. Confirma con el usuario antes de escribir.

## 1. Detectar (solo lectura)

- Stack y versiones (`package.json`, lockfile, `go.mod`, `pyproject.toml`…), comandos reales (test, lint, typecheck, build), CI.
- Lo que el equipo ya define: `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.codex/`, `.cursor/`, `CONTRIBUTING.md`, plantillas de PR, convenciones de commits/ramas, ADRs, `openspec/`.
- Bases de datos: ORMs, `DATABASE_URL` en `.env.example`, docker-compose, scripts db/migrate/seed.
- Servidores MCP de base de datos (postgres, mysql, supabase, mongodb, neon, prisma, redis…): `.mcp.json` del repo y `claude mcp list` en Claude; `codex mcp list` en Codex.
- Pregunta al usuario lo que no se deduce: restricciones del cliente (qué no tocar, entornos prohibidos, compliance), gestor de tickets, idioma de commits/PR.

## 2. Ubicación de specs (preguntar)

- **Ya tiene `openspec/`** → úsalo tal cual.
- **Dentro del repo** (el equipo lo acepta) → `openspec init --tools <herramientas> --scope global --language es --no-animation .`
- **Fuera del repo** (privado) → `openspec store setup <project-id> --path ~/openspec-stores/<project-id>`. Desde ahí, todos los comandos `openspec` del proyecto llevan `--store <project-id>`.
- **Sin SDD** (el proyecto tiene otro proceso) → sigue su proceso; anótalo.

## 2b. Frontend web: Modern Web Guidance (preguntar SIEMPRE, nunca por defecto)

Si el proyecto tiene frontend web, pregunta: "¿Activo Modern Web Guidance (Google Chrome) en este proyecto para generar HTML/CSS/JS moderno?". Solo si responde que sí:
- Copia `~/.agents/vendor/modern-web-guidance` a la carpeta de skills del proyecto de cada herramienta usada (Claude: `.claude/skills/`; otras: su ruta de skills de proyecto) y añade esa ruta a `.git/info/exclude`.
- Permite sin preguntar `npx -y modern-web-guidance@1.0.2 search *` y `… retrieve *` en los ajustes locales de la herramienta.
- Anótalo en `AGENTS.local.md`: `Frontend: Modern Web Guidance activo`.
Si responde que no, no lo instales ni lo menciones más en ese proyecto.

## 3. Escribir la capa privada

**`AGENTS.local.md`** (común a todas las herramientas; máx. ~40 líneas; solo lo específico; no repitas el global):
```
# <proyecto> — notas privadas
Specs: <in-repo | store: <id> (usar --store <id>) | sin SDD: <proceso>>
Stack: ...
Comandos: test=…, lint=…, typecheck=…, build=…
Convenciones del equipo: ramas …, commits …, PR …
Restricciones: … (lo que NO se toca)
BD: <motores/entornos>; prohibido: <prod, …>
```

**Adaptador por herramienta** (solo las que use el usuario):
- **Claude**: `CLAUDE.local.md` con solo dos líneas: `@AGENTS.local.md` y `@.agents/brain.md`. Y `.claude/settings.local.json` (solo diferencias respecto al global): `allow` con los comandos reales del proyecto; `ask`/`deny` para accesos a BD o scripts propios no cubiertos; **cada servidor MCP de BD → `ask`** con `"mcp__<servidor>"` (si apunta a producción, propón `deny`). Si existe, léelo y fusiona; nunca lo sobrescribas.
- **Otras herramientas**: leen `AGENTS.local.md` por la regla global; añade sus ajustes locales equivalentes si los tienen.

Si las specs están en el repo y el equipo no las versiona, ocúltalas igual que el resto.

## 4. Ocultar sin tocar el repo

Añade a `.git/info/exclude` (no a `.gitignore`), sin duplicar líneas, solo lo que hayas creado:
```
AGENTS.local.md
.agents/brain.md
CLAUDE.local.md
.claude/settings.local.json
```
Verifica: `git status --porcelain` no muestra ninguno de esos ficheros.

## 4b. Cerebro

Crea `.agents/brain.md` con la skill `cerebro` (reutiliza lo detectado en el paso 1).

## 5. Specs base (opcional, brownfield)

Si el usuario quiere: lista capabilities (`code-explorer`) → el usuario elige → `spec-miner` por capability (en paralelo si la herramienta lo permite), con `--store` si aplica → `openspec validate --specs`.

## 6. Resumen

3-5 líneas: dónde viven las specs, qué ficheros privados se crearon y confirmación de que `git status` está limpio.

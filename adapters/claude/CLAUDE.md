@~/.agents/AGENTS.md

# Claude Code (específico)

- En cada proyecto, `CLAUDE.local.md` importa `@AGENTS.local.md` y `@.agents/brain.md`.
- Subagentes: herramienta Agent; varios independientes en un solo mensaje. Tareas `[P]` con `isolation: "worktree"`.
- Hooks activos: bloqueo de ficheros secretos, formateo tras editar, comprobación del cerebro al iniciar sesión.

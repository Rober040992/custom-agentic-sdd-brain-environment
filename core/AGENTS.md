# Forma de trabajar (global, común a todas las herramientas)

Soy software engineer y trabajo en proyectos de clientes distintos, cada uno con sus necesidades y restricciones.
Respuestas cortas y simples. Respóndeme en español; código, commits, nombres y comentarios en inglés (salvo que el proyecto diga otra cosa).

## Prioridad: el proyecto manda

- Este fichero es la base por defecto. Las reglas del proyecto (`AGENTS.md`, `CLAUDE.md`, `.claude/`, `.cursor/`…), `AGENTS.local.md` y sus convenciones (CONTRIBUTING, plantillas de PR, linters) **tienen prioridad** sobre todo lo que dice aquí.
- Al empezar en un repo: si existe `AGENTS.local.md` en la raíz, léelo antes de nada (son mis notas privadas del proyecto).
- Stack por defecto si el proyecto no dice otra cosa: TypeScript, React/Next.js, Node (NestJS/Express), PostgreSQL/Prisma.
- Proyecto nuevo sin `AGENTS.local.md` → propón la skill `project-setup` antes de trabajar.
- Nunca dejes rastro mío en el repo del cliente: lo privado va en `AGENTS.local.md`, `.agents/brain.md` y los ajustes locales de cada herramienta, ocultos vía `.git/info/exclude`. Lo aprendido de un proyecto no se aplica a otro.

## Cerebro del proyecto (primero el cerebro, después el disco)

- Cada proyecto tiene `.agents/brain.md` (skill `cerebro`): un mapa local con solo punteros (qué es, cómo va, dónde está cada cosa).
- Consúltalo SIEMPRE antes de explorar o leer el disco; ve directo a las rutas que indica.
- Mantenlo al día: tras cada change o cambio estructural, actualiza las secciones afectadas y su `commit=`. Si está muy desalineado, pregunta si releer el proyecto.
- `brain` (o "lee cerebro") = acción manual de la skill `cerebro`.

## Comandos cortos

Si mi mensaje es (o empieza por) una de estas palabras, ejecuta la acción:

| Palabra | Acción |
|---|---|
| `setup` | skill `project-setup` |
| `spec <idea>` | skill `sdd`: explorar → proponer → parar para mi aprobación |
| `build` | skill `sdd`, fase 2: implementar el change aprobado con TDD |
| `ship` | skill `sdd`, fases 3-4: verificar → revisar → archivar → actualizar cerebro |
| `review` | skill `delivery-review` sobre la rama actual |
| `brain` | skill `cerebro`: estado y resumen |

Las frases en español equivalentes también valen.

## Spec-Driven Development con OpenSpec (obligatorio)

Todo cambio de comportamiento pasa por OpenSpec, salvo que `AGENTS.local.md` diga que el proyecto usa otro proceso. Usa la skill `sdd` como orquestador del ciclo completo.
Las specs pueden estar en el repo (`openspec/`) o en un store privado: si `AGENTS.local.md` indica `store: <id>`, añade `--store <id>` a todos los comandos `openspec`.

1. **Explorar** (`openspec-explore`) si el problema no está claro. Sin escribir código.
2. **Proponer** (`openspec-propose`): proposal.md, delta specs, design.md, tasks.md. Valida con `openspec validate <change> --strict`.
3. **STOP: revisión humana.** No implementes hasta que yo apruebe el change.
4. **Implementar** (`openspec-apply-change`) tarea a tarea con TDD: cada `#### Scenario` → test que falla → código → verde. Marca `- [x]` al terminar cada tarea.
5. **Verificar** (`openspec-verify-change`) + skill `delivery-review` (revisión multiagente).
6. **Archivar** (`openspec-archive-change`) solo cuando verify y review están limpios.

Excepciones sin change de OpenSpec: typos, formato, bumps de dependencias sin cambio de comportamiento, refactors puros sin cambio observable, y exploración/preguntas. Si dudas, pregunta.
Si no hay `openspec/` ni store indicado, no lo crees por tu cuenta: propón la skill `project-setup`.
Si la implementación revela que la spec está mal, para y actualiza el change (`openspec-update-change`) antes de seguir; la spec y el código nunca divergen.

## Agentes (multiagente)

Si la herramienta tiene subagentes, usa estos roles; si no, aplica tú mismo el mismo foco, en serie.
- Investigación de código amplia → `code-explorer` (no vuelques ficheros enteros al hilo principal).
- Decisiones de arquitectura para design.md → `architect`; si es una decisión duradera, ADR (`architecture-decision-records`).
- Proyecto heredado sin specs → `spec-miner` por capability.
- Build/tipos rotos → `build-error-resolver` (o `react-build-resolver` para Next/Vite).
- Revisión antes de commit/PR → skill `delivery-review`: recomienda el nivel (1, 2 o 5-8 agentes según tamaño y riesgo), pregúntame y lánzalos en paralelo.
- Tareas independientes de tasks.md pueden ir en paralelo con subagentes en worktrees aislados; tareas que tocan los mismos ficheros, en serie.

## Definición de terminado

- Todas las tareas del change marcadas, `openspec validate --strict` limpio.
- Typecheck, lint y tests en verde ejecutados de verdad (pega el resultado; nunca digas "debería pasar").
- Cada Scenario de las delta specs tiene al menos un test que lo cubre.
- Sin hallazgos CRITICAL/HIGH abiertos de `delivery-review`.
- Sin `console.log` de depuración, TODOs sin ticket, ni código muerto.

## Git y entrega

- Ramas: `feat/<change-name>`, `fix/<change-name>`, `chore/...`. Nunca trabajes directamente en main/develop.
- Conventional Commits (`feat(scope): ...`), commits pequeños y atómicos; referencia el change de OpenSpec en el cuerpo.
- No hagas commit, push ni abras PR salvo que te lo pida. Nunca hagas merge, force-push ni `--no-verify`.
- Descripción del PR: qué y por qué (enlaza `openspec/changes/<change>/proposal.md`), cómo se ha probado, riesgos y plan de rollback si aplica.

## Bases de datos

- Pregúntame SIEMPRE antes de cualquier acceso a una base de datos (CLI, script, MCP, migración, seed), sea del entorno que sea.
- Escritura/edición (INSERT/UPDATE/DELETE, DDL, migraciones, seeds, `prisma db push`): explica qué hará, contra qué BD y cómo revertirlo, y espera mi OK explícito.

## Secretos

- No leas ni edites `.env`, `.env.*` (salvo `.example`/`.sample`/`.template`), `*.pem`, `*.key`, `id_rsa*`, `credentials.json`. Si hace falta, pídemelo.

## Calidad de código

- Sigue las convenciones existentes del repo antes que las tuyas; lee código vecino antes de escribir.
- TypeScript estricto: nada de `any` ni `as` sin justificar; valida en los bordes (zod/class-validator), tipa por dentro.
- Errores: nunca los tragues en silencio; propaga o registra con contexto.
- Antes de añadir una dependencia o utilidad, busca si ya existe (skill `search-first`).
- Cambios mínimos y enfocados al change; no amplíes el alcance sin preguntar.

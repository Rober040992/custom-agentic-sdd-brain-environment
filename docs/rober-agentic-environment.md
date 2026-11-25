# Rober's Agentic Environment

> A personal Claude Code setup for professional software delivery: **Spec-Driven Development (OpenSpec) + multi-agent review + a per-project "brain" + safety rails**, adapted to each client project without leaving traces in it.

**This file has two uses:**
1. **Documentation**: what the environment is, how it is built, how and when to use it, and why.
2. **Bootstrap prompt**: give this file to any Claude Code session with the message *"Build this environment on my machine following the Rebuild Instructions"*, and it can recreate the whole setup in one go. Part 2 contains every file verbatim.

---

# Part 1: Overview

## What it is

A layer on top of Claude Code that makes it behave like a disciplined senior engineer:

| Piece | What it does |
|---|---|
| **SDD with OpenSpec** | Every behavior change starts with a spec (proposal → requirements with scenarios → design → tasks). No code before approval. |
| **Multi-agent** | Specialist subagents explore, design, test-drive and review in parallel. |
| **Brain** (`.claude/brain.md`) | A per-project, pointer-only map, so Claude does not re-read the repo every session. |
| **Per-project overlay** | Private config per project (`CLAUDE.local.md`, `settings.local.json`), hidden from git. Projects never contaminate each other. |
| **Safety rails** | Asks before any database access. Blocks secrets, force-push and merges. Auto-formats code. |

**What it is not:** an "AI factory". It is human-in-the-loop by design: you approve every spec and you decide on commits and PRs.

## Why

- **Quality over volume**: specs turn vague requests into testable scenarios; TDD and multi-agent review catch bugs before the PR.
- **Client projects differ**: a fixed global setup breaks. Here the project always wins and the global config is only a default.
- **Token economy**: the brain plus pointer-only context avoids re-reading the codebase.
- **Safety**: client databases and secrets are protected by hard rules, not by trusting the model.

## How it is built (layers)

```
~/.claude/                          GLOBAL (default, applies everywhere)
├── CLAUDE.md                       working rules (project rules override these)
├── settings.json                   permissions (allow/ask/deny) + hooks
├── hooks/                          protect-secrets, format-prettier, brain-check
├── agents/                         14 specialists (curated from ECC)
├── skills/                         sdd, delivery-review, project-setup, cerebro
│                                   + 12 openspec-* (official) + 17 patterns (ECC)
├── rules/typescript, rules/react   path-scoped, load only when touching .ts/.tsx
└── vendor/modern-web-guidance      opt-in per project, never global

<client-repo>/                      PER PROJECT (private, in .git/info/exclude)
├── CLAUDE.local.md                 project notes: stack, commands, constraints, DB
│                                   + "@.claude/brain.md" import
├── .claude/settings.local.json     project-specific permissions
├── .claude/brain.md                the brain
└── .claude/skills/modern-web-guidance   (only if approved in setup)

~/openspec-stores/<project>/        OPTIONAL: specs kept outside the client repo
```

Precedence: **project CLAUDE.md / team conventions > CLAUDE.local.md > global CLAUDE.md**.

## When to use what

| Situation | Say | What happens |
|---|---|---|
| First time in a project | "prepara este proyecto" | `project-setup`: detect stack, choose where specs live, ask about Modern Web Guidance, create the private overlay and the brain |
| New feature / bug fix | "nuevo change: <description>" | `sdd`: explore → propose → **STOP for approval** |
| Approved spec | "implementa el change" | TDD implementation, parallel agents for `[P]` tasks |
| Finish | "cierra el change" | verify → multi-agent review → archive → update brain |
| Review a branch | "revisa la rama" | `delivery-review` (5–8 reviewers in parallel) |
| Check project memory | "lee cerebro" | brain status and summary; asks whether to re-read the repo if it is stale |
| Typos, formatting, pure refactors | just ask | no OpenSpec needed |

## The flow

```
0. project-setup (once)  ──► CLAUDE.local.md + settings.local.json + brain.md
1. "nuevo change: X"
2. Explore      code-explorer (+ architect) in parallel        0–2 agents
3. Propose      openspec-propose: proposal/specs/design/tasks  0 agents
4. ⛔ STOP      human approves the spec
5. Implement    per task: scenario → failing test → code → green
                [P] tasks → parallel agents in isolated worktrees   0–N agents
6. Verify       typecheck + lint + tests + build (really run) + openspec verify
7. Review       delivery-review: Claude recommends level and asks   1 / 2 / 5–8 agents
8. Close        archive change → update brain → commit/PR only if asked
```

Always on: the brain-check at session start, DB access asks for confirmation, secrets are blocked, prettier runs on edited files.

## Agents per step

| Step | Agents | Models |
|---|---|---|
| Explore | `code-explorer`, `architect` (only if needed) | sonnet / opus |
| Implement | `tdd-guide`, worktree subagents for `[P]` tasks, `build-error-resolver` / `react-build-resolver` if the build breaks | sonnet |
| Review: level chosen with the user (1 / 2 / 5–8) | | |
| Review (Full, always) | `code-reviewer`, `security-reviewer`, `silent-failure-hunter`, `pr-test-analyzer`, spec-compliance (general-purpose) | sonnet |
| Review (by file type) | `typescript-reviewer`, `react-reviewer`, `database-reviewer` | sonnet |
| Brownfield specs | `spec-miner` (one per capability) | opus |

Typical task: **1–9 agents total**, depending on the review level. Code itself is written by the main Claude (0 agents) unless there are `[P]` tasks.

## The brain

- `.claude/brain.md`, local, at most ~150 lines, **pointers only** (paths plus one-line explanations, never copied code).
- Sections: **What it is · How it works · Where (concept → path) · Status**.
- First line stores `<!-- brain: commit=<sha> date=<date> -->`.
- Auto-loaded through `@.claude/brain.md` in `CLAUDE.local.md`.
- The `SessionStart` hook compares the stored commit with `HEAD`:
  - ✅ up to date → use the brain before reading the disk
  - ⚠️ N files changed → update the affected sections when working there
  - ❌ more than 60 files changed, or the commit is missing → ask the user whether to re-read the project
- Updated incrementally after every archived change.
- The hook also reports uncommitted changes.

## Tiny example

```
You:    prepara este proyecto
Claude: Next.js 15 + Prisma + Postgres detected. Specs: in repo or private store?
        Frontend detected: enable Modern Web Guidance?
You:    store privado, sí
Claude: Created CLAUDE.local.md, settings.local.json, brain.md, store "acme-shop".
        git status clean.

You:    nuevo change: los usuarios pueden marcar productos como favoritos
Claude: [code-explorer maps products + auth]
        Change "add-product-favorites": 2 requirements, 5 scenarios
        (add, remove, list, unauthenticated → 401, duplicate → idempotent), 6 tasks (2 [P]).
        Out of scope: favorites sharing. ⛔ Waiting for approval.
You:    ok
Claude: [prisma migration → asks before running it]
        Tasks 6/6 ✓ · tests 42/42 ✓ · typecheck ✓ · lint ✓
        delivery-review: 1 HIGH fixed (missing authz on DELETE), 0 open.
        Archived, brain updated. Want commits + PR?
```

---

# Part 2: Rebuild Instructions (for Claude)

> **Claude: follow these steps in order on macOS/Linux. Confirm with the user before overwriting any existing file in `~/.claude` (back it up first as `<file>.bak`). Merge `settings.json` instead of replacing it. At the end, report what was installed in five lines or fewer.**

## Step 1: Prerequisites

- Node.js ≥ 22. With nvm: `nvm install 22 && nvm alias default 22`.
- `npm i -g @fission-ai/openspec@latest`
- `brew install gh jq` (or the distro equivalent)
- `openspec config set telemetry.enabled false`

## Step 2: OpenSpec official skills (global)

```bash
openspec config set workflows '["propose","explore","new","continue","ff","apply","verify","update","sync","archive","bulk-archive","onboard"]'
openspec config set profile custom
# run inside any throwaway git repo; it installs the skills globally to ~/.agents/skills and symlinks them into ~/.claude/skills
mkdir -p /tmp/os-boot && cd /tmp/os-boot && git init -q && OPENSPEC_TELEMETRY=0 openspec init --tools claude --scope global --language es --no-animation . && rm -rf /tmp/os-boot
ls ~/.claude/skills | grep openspec   # expect 12
```

## Step 3: Curated agents, skills and rules from ECC

Source: `https://github.com/affaan-m/ECC` (reference commit `4adeee6732a12d1540f49a4d50a38ce8c97f9a53`). **Do not run ECC's install.sh**: it installs 72 agents, 328 skills and about 28 heavy hooks. Clone it into a temporary directory, then copy only the items below with this script:

```python
# save as install_ecc.py, run with: python3 -I install_ecc.py <path-to-ECC-clone>
import sys, shutil, re, pathlib
src = pathlib.Path(sys.argv[1]); home = pathlib.Path.home() / ".claude"
agents = "architect code-explorer code-reviewer security-reviewer silent-failure-hunter pr-test-analyzer build-error-resolver react-build-resolver tdd-guide spec-miner typescript-reviewer react-reviewer database-reviewer refactor-cleaner".split()
skills = "tdd-workflow verification-loop git-workflow api-design architecture-decision-records search-first nestjs-patterns backend-patterns typescript-patterns react-patterns nextjs-turbopack frontend-patterns postgres-patterns prisma-patterns database-migrations security-review e2e-testing".split()
(home/"agents").mkdir(exist_ok=True)
for a in agents: shutil.copy(src/"agents"/f"{a}.md", home/"agents"/f"{a}.md")
for s in skills:
    d = home/"skills"/s
    if d.exists(): shutil.rmtree(d)
    shutil.copytree(src/"skills"/s, d)
for lang, files in {"typescript": ["coding-style","patterns","security","testing"], "react": ["coding-style","hooks","patterns","security","testing"]}.items():
    d = home/"rules"/lang; d.mkdir(parents=True, exist_ok=True)
    for f in files: shutil.copy(src/"rules"/lang/f"{f}.md", d/f"{f}.md")

def sub(path, old, new, regex=False):
    p = home/path; t = p.read_text()
    n = len(re.findall(old, t)) if regex else t.count(old)
    if n == 0: sys.exit(f"PATCH MISS in {path}: {old[:60]!r}")
    p.write_text(re.sub(old, new, t) if regex else t.replace(old, new))

# 1) Stop reviewers from auto-spawning after every edit (review is orchestrated by delivery-review)
sub("agents/code-reviewer.md", "Use immediately after writing or modifying code. MUST BE USED for all code changes.", "Use when reviewing a diff before commit/PR (orchestrated by the delivery-review skill).")
sub("agents/typescript-reviewer.md", "Use for all TypeScript and JavaScript code changes. MUST BE USED for TypeScript/JavaScript projects.", "Use when reviewing TypeScript/JavaScript diffs before commit/PR.")
sub("agents/react-reviewer.md", "Use for any change touching .tsx/.jsx files or React component logic. MUST BE USED for React projects.", "Use when reviewing diffs touching .tsx/.jsx or React component logic.")
sub("agents/tdd-guide.md", "Use PROACTIVELY when writing new features, fixing bugs, or refactoring code. Ensures 80%+ test coverage.", "Use when implementing OpenSpec tasks or fixing bugs test-first: turns #### Scenario blocks into failing tests, then implements. Targets 80%+ coverage on changed code.")
# 2) tdd-workflow: drop dependency on ECC scripts
p = home/"skills/tdd-workflow/SKILL.md"; t = p.read_text()
a = t.index("1. **Resolve the package manager.**"); b = t.index("2. **Distinguish the package manager")
p.write_text(t[:a] + "1. **Resolve the package manager** from the project under test, in order: `package.json` `packageManager` field, then lockfile (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb`/`bun.lock` → bun, `package-lock.json` → npm); default to npm.\n\n" + t[b:])
# 3) typescript-patterns: fix rule paths
sub("skills/typescript-patterns/SKILL.md", "`rules/typescript/coding-style.md` and `rules/typescript/patterns.md` in this repository, installed as `rules/ecc/typescript/coding-style.md` and `rules/ecc/typescript/patterns.md`", "`~/.claude/rules/typescript/coding-style.md` and `~/.claude/rules/typescript/patterns.md`")
sub("skills/typescript-patterns/SKILL.md", "TypeScript rules (`rules/typescript/`, installed as `rules/ecc/typescript/`)", "TypeScript rules (`~/.claude/rules/typescript/`)")
# 4) spec-miner: its original format FAILS `openspec validate` (needs ## Purpose + ## Requirements, no ### Invariant blocks)
sm = "agents/spec-miner.md"
sub(sm, "Produces flat Requirement and Invariant blocks", "Produces flat Requirement blocks (invariants included as Requirements)")
sub(sm, "**The file contains only `### Requirement:` and `### Invariant:` blocks. No type chapters.", "**The file has `## Purpose` then `## Requirements`, which contains only `### Requirement:` blocks (invariants are Requirements whose name ends in `(invariant)`). No type chapters.")
sub(sm, "# Spec: [capability-name]\n\n> Auto-extracted by spec-miner. Last mined: YYYY-MM-DD.\n> Source: [key files analyzed]\n> Last verified: YYYY-MM-DD (commit abc1234)\n\n---\n", "# [capability-name] Specification\n\n<!-- Auto-extracted by spec-miner. Last mined: YYYY-MM-DD. Source: [key files analyzed]. Last verified: YYYY-MM-DD (commit abc1234) -->\n\n## Purpose\n[2-3 sentences (50+ chars) describing what this capability is responsible for.]\n\n## Requirements\n")
sub(sm, r"### Invariant: \[([^\]]+)\]\n((?:<!--.*-->\n)+)\n(\[[^\n]*\])\n(\n> Last verified[^\n]*\n)?", r"### Requirement: [\1] (invariant)\n\2\n\3\n\n#### Scenario: [violation attempt is rejected]\n- **WHEN** [an operation would break the invariant]\n- **THEN** [it is rejected / state stays consistent]\n", regex=True)
sub(sm, "1. **Only two block types**: `### Requirement:` for triggered behaviors, `### Invariant:` for always-true constraints. Nothing else at the `###` level.", "1. **Only one block type**: `### Requirement:` under `## Requirements`. Always-true constraints are Requirements named `<name> (invariant)`. Nothing else at the `###` level. `## Purpose` is mandatory (50+ chars).")
sub(sm, "10. **Invariants do not have Scenarios** — they are not triggered, they are always true. They MAY have a `verified_by` test reference.", "10. **Invariants still need a Scenario** (OpenSpec validation requires it): describe the attempt to violate it and the expected rejection. They MAY have a `verified_by` test reference.")
sub(sm, "| Has at least one `#### Scenario:` | Has no Scenarios; MAY have `<!-- verified_by: -->` |", "| Has at least one `#### Scenario:` | Named `... (invariant)`; one violation Scenario; MAY have `<!-- verified_by: -->` |")
sub(sm, "- FAIL: Using `###` for anything other than `Requirement:` or `Invariant:` — breaks OpenSpec delta compatibility", "- FAIL: Using `###` for anything other than `Requirement:` — breaks OpenSpec validation and delta compatibility\n- FAIL: Finishing without running `openspec validate <capability> --type spec` and fixing every ERROR")
sub(sm, "8. **Record the commit.**", "9. **Validate.** After writing each spec run `openspec validate <capability> --type spec` (read-only) and fix all ERRORs.\n8. **Record the commit.**")
print("ok")
```

After that, patch `~/.claude/skills/search-first/SKILL.md`: replace every mention of the nonexistent "researcher agent" with "a general-purpose research subagent".

If ECC has changed and a patch reports `PATCH MISS`, apply the same intent by hand. Before copying, review the files for network calls or telemetry.

## Step 4: Modern Web Guidance (vendored, opt-in per project)

```bash
git clone --depth 1 https://github.com/googlechrome/modern-web-guidance /tmp/mwg
mkdir -p ~/.claude/vendor && cp -R /tmp/mwg/skills/modern-web-guidance ~/.claude/vendor/ && rm -rf /tmp/mwg
```
Pin the version: `sed -i '' 's/modern-web-guidance@latest/modern-web-guidance@1.0.2/g' ~/.claude/vendor/modern-web-guidance/SKILL.md`. Do **not** put it in `~/.claude/skills`. `project-setup` installs it per project, and only when the user approves.

## Step 5: Hooks (`~/.claude/hooks/`, then `chmod +x`)

**`protect-secrets.sh`**
```bash
#!/usr/bin/env bash
# PreToolUse (Edit|Write): block writes to secret files.
f=$(jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0
b=$(basename "$f")
case "$b" in
  .env.example|.env.sample|.env.template) exit 0 ;;
  .env|.env.*|*.pem|*.key|id_rsa*|id_ed25519*|credentials.json|*.p12|*.pfx)
    jq -n --arg f "$f" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:("Protected secret file: " + $f + ". Edit it manually.")}}'
    exit 0 ;;
esac
exit 0
```

**`format-prettier.sh`** (prettier > biome > eslint --fix)
```bash
#!/usr/bin/env bash
# PostToolUse (Edit|Write): format the edited file with the project's own tool: prettier > biome > eslint --fix.
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[ -f "$f" ] || exit 0
case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.md|*.yaml|*.yml) ;; *) exit 0 ;; esac
case "$f" in */node_modules/*|*/openspec/*) exit 0 ;; esac
d=$(dirname "$f")
while [ "$d" != "/" ]; do
  b="$d/node_modules/.bin"
  if [ -x "$b/prettier" ]; then "$b/prettier" --write --log-level warn --ignore-unknown "$f"; exit 0; fi
  if [ -x "$b/biome" ]; then (cd "$d" && "$b/biome" format --write "$f" >/dev/null); exit 0; fi
  if [ -x "$b/eslint" ]; then
    case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) (cd "$d" && "$b/eslint" --fix "$f" >/dev/null) ;; esac
    exit 0
  fi
  [ -f "$d/package.json" ] && [ -d "$d/.git" ] && exit 0
  d=$(dirname "$d")
done
exit 0
```

**`brain-check.sh`**
```bash
#!/usr/bin/env bash
# SessionStart: tell Claude whether the project's brain (.claude/brain.md) is fresh.
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
brain="$root/.claude/brain.md"
dirty=$(git -C "$root" status --porcelain 2>/dev/null | grep -v " \.claude/" | grep -c .)
extra=""; [ "$dirty" -gt 0 ] && extra=" Además hay $dirty ficheros sin commitear: tenlos en cuenta si afectan al cerebro."
say() { jq -n --arg m "$1$extra" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'; exit 0; }
if [ ! -f "$brain" ]; then
  [ -f "$root/CLAUDE.local.md" ] && say "CEREBRO: este proyecto no tiene .claude/brain.md. Propón crearlo (skill cerebro)."
  exit 0
fi
sha=$(grep -o 'commit=[0-9a-f]*' "$brain" | head -1 | cut -d= -f2)
[ -z "$sha" ] && say "CEREBRO: .claude/brain.md no tiene commit registrado; trátalo como posiblemente desactualizado."
head=$(git -C "$root" rev-parse HEAD 2>/dev/null)
if ! git -C "$root" cat-file -e "$sha^{commit}" 2>/dev/null; then
  say "CEREBRO: el commit $sha del cerebro no existe en este repo (rebase/otra rama). Pregunta al usuario si releer el proyecto para realinearlo."
fi
case "$head" in "$sha"*) say "CEREBRO: al día (commit ${sha:0:8}). Úsalo antes de leer el disco." ;; esac
files=$(git -C "$root" diff --name-only "$sha" HEAD | grep -v '^\.claude/')
n=$(printf '%s\n' "$files" | grep -c .)
[ "$n" -eq 0 ] && say "CEREBRO: al día (sin cambios relevantes desde ${sha:0:8}). Úsalo antes de leer el disco."
list=$(printf '%s\n' "$files" | head -25 | tr '\n' ' ')
if [ "$n" -gt 60 ]; then
  say "CEREBRO DESACTUALIZADO: $n ficheros cambiados desde ${sha:0:8}. Pregunta al usuario si releer el proyecto para realinear el cerebro. Muestra: $list"
fi
say "CEREBRO desactualizado: $n ficheros cambiados desde ${sha:0:8}: $list. Cuando trabajes en esas zonas, actualiza las secciones afectadas del cerebro y su commit."
```

(Hook messages are in Spanish to match the user's language; translate if needed.)

Pipe-test each one, for example: `echo '{"tool_input":{"file_path":"/x/.env"}}' | ~/.claude/hooks/protect-secrets.sh` should print a deny decision.

## Step 6: `~/.claude/settings.json` (MERGE with the existing file; keep its plugins and theme)

```json
{
  "env": { "OPENSPEC_TELEMETRY": "0" },
  "permissions": {
    "allow": [
      "Bash(openspec list *)", "Bash(openspec show *)", "Bash(openspec status *)", "Bash(openspec validate *)",
      "Bash(openspec context *)", "Bash(openspec instructions *)",
      "Bash(git status *)", "Bash(git diff *)", "Bash(git log *)", "Bash(git show *)", "Bash(git branch *)", "Bash(git merge-base *)",
      "Bash(gh pr view *)", "Bash(gh pr diff *)", "Bash(gh pr checks *)", "Bash(gh run view *)",
      "Bash(npm test *)", "Bash(npm run test *)", "Bash(npm run lint *)", "Bash(npm run typecheck *)",
      "Bash(pnpm test *)", "Bash(pnpm lint *)", "Bash(pnpm typecheck *)",
      "Bash(npx tsc --noEmit *)", "Bash(npx vitest run *)", "Bash(npx jest *)"
    ],
    "deny": [
      "Read(**/.env)", "Read(**/.env.local)", "Read(**/.env.*.local)", "Read(**/.env.production)",
      "Read(**/*.pem)", "Read(**/*.key)",
      "Bash(git push --force *)", "Bash(git push -f *)", "Bash(gh pr merge *)"
    ],
    "ask": [
      "Bash(psql *)", "Bash(pg_dump *)", "Bash(pg_restore *)", "Bash(mysql *)", "Bash(mongosh *)", "Bash(mongo *)",
      "Bash(redis-cli *)", "Bash(sqlite3 *)",
      "Bash(*prisma migrate *)", "Bash(*prisma db *)", "Bash(*prisma studio*)", "Bash(*drizzle-kit *)",
      "Bash(*typeorm *)", "Bash(*knex *)", "Bash(*sequelize *)", "Bash(supabase db *)",
      "Bash(*npm run db*)", "Bash(*pnpm db*)", "Bash(*npm run migrate*)", "Bash(*pnpm migrate*)", "Bash(*seed*)"
    ]
  },
  "hooks": {
    "PreToolUse":  [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "~/.claude/hooks/protect-secrets.sh", "timeout": 10 }] }],
    "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "~/.claude/hooks/format-prettier.sh 2>/dev/null || true", "timeout": 30 }] }],
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/brain-check.sh", "timeout": 10 }] }]
  }
}
```
Validate it with `jq -e . ~/.claude/settings.json`. Auto mode may refuse to let Claude edit its own permissions; in that case, write the merged file to a temporary path and ask the user to copy it.

## Step 7: `~/.claude/CLAUDE.md`

~~~markdown
# Working agreement (global)

I'm a software engineer working on different client projects, each with its own needs and constraints.
Keep answers short and simple. Reply in Spanish; code, commits, identifiers and comments in English (unless the project says otherwise).

## Priority: the project wins

- This file is the default baseline. The project's `CLAUDE.md`, `CLAUDE.local.md`, `.claude/` and its conventions (CONTRIBUTING, PR templates, linters) **take precedence** over anything here.
- Default stack if the project says nothing: TypeScript, React/Next.js, Node (NestJS/Express), PostgreSQL/Prisma.
- New project without `CLAUDE.local.md` → propose the `project-setup` skill before working.
- Never leave my traces in the client repo: private things go in `CLAUDE.local.md` and `.claude/settings.local.json`, hidden via `.git/info/exclude`. What is learned in one project does not apply to another.

## Project brain (brain first, disk second)

- Each project has `.claude/brain.md` (`cerebro` skill): a local, pointer-only map (what it is, how it works, where things live).
- ALWAYS consult it before exploring or reading the disk; go straight to the paths it lists.
- Keep it current: after each change or structural change, update the affected sections and its `commit=`. If it is badly out of sync, ask whether to re-read the project.
- "lee cerebro" = manual action of the `cerebro` skill.

## Spec-Driven Development with OpenSpec (mandatory)

Every behavior change goes through OpenSpec, unless `CLAUDE.local.md` says the project uses another process. Use the `sdd` skill to orchestrate the full cycle.
Specs may live in the repo (`openspec/`) or in a private store: if `CLAUDE.local.md` says `store: <id>`, add `--store <id>` to every `openspec` command.

1. **Explore** (`openspec-explore`) if the problem is unclear. No code.
2. **Propose** (`openspec-propose`): proposal.md, delta specs, design.md, tasks.md. Validate with `openspec validate <change> --strict`.
3. **STOP: human review.** Do not implement until I approve the change.
4. **Implement** (`openspec-apply-change`) task by task with TDD: each `#### Scenario` → failing test → code → green. Tick `- [x]` after each task.
5. **Verify** (`openspec-verify-change`) + `delivery-review` skill (parallel multi-agent review).
6. **Archive** (`openspec-archive-change`) only when verify and review are clean.

No OpenSpec change needed for: typos, formatting, dependency bumps without behavior change, pure refactors with no observable change, exploration/questions. If in doubt, ask.
If there is no `openspec/` and no store, do not create one on your own: propose `project-setup`.
If implementation shows the spec is wrong, stop and update the change (`openspec-update-change`) before continuing; spec and code never diverge.

## Agents (multi-agent)

- Broad code investigation → `code-explorer` (do not dump whole files into the main thread).
- Architecture decisions for design.md → `architect`; durable decisions → ADR (`architecture-decision-records`).
- Legacy project without specs → `spec-miner` per capability.
- Broken build/types → `build-error-resolver` (or `react-build-resolver` for Next/Vite).
- Review before commit/PR → `delivery-review` skill: recommend the level (1, 2 or 5–8 agents by size and risk), ask me, then launch them in parallel.
- Independent tasks in tasks.md may run in parallel as subagents in isolated worktrees; tasks touching the same files run serially.

## Definition of done

- All change tasks ticked, `openspec validate --strict` clean.
- Typecheck, lint and tests green, actually executed (paste the result; never say "should pass").
- Every Scenario in the delta specs is covered by at least one test.
- No open CRITICAL/HIGH findings from `delivery-review`.
- No debug `console.log`, TODOs without a ticket, or dead code.

## Git and delivery

- Branches: `feat/<change-name>`, `fix/<change-name>`, `chore/...`. Never work directly on main/develop.
- Conventional Commits (`feat(scope): ...`), small atomic commits; reference the OpenSpec change in the body.
- Do not commit, push or open PRs unless I ask. Never merge, force-push or use `--no-verify`.
- PR description: what and why (link `openspec/changes/<change>/proposal.md`), how it was tested, risks and rollback plan if relevant.

## Databases

- ALWAYS ask me before any database access (CLI, script, MCP, migration, seed), in any environment.
- Writes/edits (INSERT/UPDATE/DELETE, DDL, migrations, seeds, `prisma db push`): explain what it will do, against which DB and how to revert it, and wait for my explicit OK.

## Code quality

- Follow the repo's existing conventions before your own; read neighboring code before writing.
- Strict TypeScript: no `any` or `as` without justification; validate at the edges (zod/class-validator), type internally.
- Errors: never swallow them silently; propagate or log with context.
- Before adding a dependency or utility, check whether it already exists (`search-first` skill).
- Minimal, focused changes; do not expand scope without asking.
~~~

## Step 8: Custom skills (`~/.claude/skills/<name>/SKILL.md`)

### `sdd/SKILL.md`
~~~markdown
---
name: sdd
description: Orchestrates the full Spec-Driven Development cycle with OpenSpec and subagents — explore, propose, human approval gate, TDD implementation, verify, multi-agent review, archive, commit/PR. Use when the user asks to build a feature, fix a bug or change behavior in a repo that has an openspec/ directory or store, or says "sdd", "nuevo change", "implementa el change", "cierra el change".
---

# SDD: full OpenSpec cycle

You orchestrate; the `openspec-*` skills do each phase's work. Detect the change's phase (`openspec list --json`, `openspec status --change <name> --json`) and continue from there. Never skip the approval gate.

## Phase 0: context (always)
- Read `CLAUDE.local.md` and the project's `CLAUDE.md`: they override this skill (conventions, commands, constraints).
- Specs: if `CLAUDE.local.md` says `store: <id>`, pass `--store <id>` to every `openspec-*` command and skill. No `openspec/` and no store → stop and offer `project-setup`. If the project uses another process (no SDD), follow it and do not impose OpenSpec.
- Read the OpenSpec `config.yaml` (repo or store).
- Detect the package manager (lockfile) and the real `typecheck`, `lint`, `test`, `build` commands. Keep them for phases 3–4.
- Create or switch to branch `feat|fix/<change-name>` if on main/develop (ask first if there are uncommitted changes).

## Phase 1: explore and propose
1. If the request is ambiguous or touches unfamiliar code, launch `code-explorer` (plus `architect` for design decisions) **in parallel** with paths and a concrete question; keep only their conclusions.
2. Run `openspec-propose` (or `openspec-new-change` + `openspec-continue-change` to go artifact by artifact).
3. Delta specs: every Requirement uses SHALL/MUST and has at least one `#### Scenario` WHEN/THEN, including error and edge cases.
4. `tasks.md`: small (≤1–2 h), verifiable tasks ordered by dependency; mark parallelizable ones (disjoint files) with `[P]`.
5. `openspec validate <change> --strict` until there are no errors.
6. **GATE: present a summary (scope, out of scope, risks, open decisions) and STOP.** No implementation without explicit approval.

## Phase 2: implement (after approval)
Run `openspec-apply-change` with these extra rules:
- **TDD per task**: turn the affected Scenarios into failing tests, run them and confirm they fail for the right reason. Then implement the minimum to pass and refactor. May delegate to `tdd-guide`.
- **Parallelism**: independent `[P]` groups may go to subagents in isolated worktrees (`isolation: "worktree"`) with their task, Scenarios, allowed files and test commands. Integrate and run the full suite afterwards. Anything not clearly independent runs serially.
- Non-trivial build/type breakage → `build-error-resolver` or `react-build-resolver`.
- After each task: relevant tests green, then `- [x]` in tasks.md.
- If the spec turns out wrong or incomplete: **stop**, explain, update via `openspec-update-change`, then continue.

## Phase 3: verify and review
1. Real gates: typecheck, lint, tests (with coverage if available), build. Paste the actual output summary.
2. `openspec-verify-change`.
3. `delivery-review` skill on the branch diff: recommend the level (1, 2 or 5–8 agents) and ask.
4. Fix CRITICAL/HIGH and re-run the affected gates. MEDIUM: fix or justify.

## Phase 4: close
1. `openspec-archive-change`, then `openspec validate --specs`.
2. Update the brain (`cerebro` skill, incremental mode) with structural, flow or path changes.
3. **Only if the user asks**: atomic Conventional Commits, push and `gh pr create` with sections: What & why (link to the proposal) · Changes · How it was tested · Risks / rollback.

## Final report
Short table: phase → status, tasks X/Y, gates (✓/✗ with command), review findings resolved or pending, next step.
~~~

### `delivery-review/SKILL.md`
~~~markdown
---
name: delivery-review
description: Multi-agent pre-merge review of the current branch diff — runs spec-compliance, code quality, security, silent-failure, test-coverage and stack-specific reviewers in parallel, then deduplicates and ranks findings. Use before committing/opening a PR, at the end of an OpenSpec change, or when the user says "revisa la rama", "review de entrega", "delivery review".
---

# Delivery review (multi-agent)

## 1. Prepare context (you, not the subagents)
- Base: `git merge-base HEAD origin/main` (or develop if that is the base branch).
- `git diff --stat <base>...HEAD` plus changed files (include uncommitted: `git status --porcelain`).
- Active OpenSpec change: `openspec list --json` → paths to proposal, design, tasks and delta specs.
- Diff over ~2000 lines → warn and propose reviewing by module.

## 1b. Choose the level (recommend, then ask)
| Level | Agents | When |
|---|---|---|
| **Minimal** | 1: `code-reviewer` (also checks the spec) | Small change (≲100 lines, 1–3 files), no sensitive areas |
| **Light** | 2: `code-reviewer` + spec/test compliance | Medium change, no sensitive areas |
| **Full** | 5–8: all reviewers below | Large change or sensitive areas: auth, permissions, payments, personal data, DB/migrations, public APIs, security |

Recommend a level with a one-line reason and ask before launching. If the user already chose, do not ask. Sensitive areas → always recommend Full.

## 2. Launch reviewers IN PARALLEL (one message, several Agent calls)
Launch only the chosen level's reviewers; Full uses the list below.
Each prompt includes the base, the file list, the change path and this mandatory output format:
`[SEVERITY CRITICAL|HIGH|MEDIUM|LOW] file:line — problem — concrete failure scenario — suggested fix`. Only findings verified in the code; no style issues the linter already covers.

Always:
- `code-reviewer`: correctness, readability, repo conventions.
- `security-reviewer`: user input, authz/authn, secrets, injection, SSRF.
- `silent-failure-hunter`: swallowed errors, dangerous fallbacks.
- `pr-test-analyzer`: do tests cover every `#### Scenario` in the delta specs? List the uncovered ones.
- **Spec compliance** (`general-purpose`): for each Requirement/Scenario, where it is implemented (file:line) and whether it holds; also flag implemented behavior that is not in the spec (scope creep).

By files touched:
- `.ts/.js` → `typescript-reviewer`
- `.tsx/.jsx` → `react-reviewer`
- SQL, migrations, `schema.prisma` → `database-reviewer`

## 3. Consolidate (you)
1. Deduplicate (same file:line and same cause → one finding, citing which reviewers agree).
2. **Verify every CRITICAL/HIGH** by reading the code yourself; drop false positives and say how many.
3. Report:
```
## Delivery review — <branch> vs <base>
Verdict: ✅ ready | ⚠️ ready with caveats | ❌ blocked
| Sev | File:line | Problem | Fix | Source |
Spec coverage: N/M Scenarios tested (missing: ...)
```
4. Do not apply fixes unless the user asks or you come from `sdd` Phase 3. In that case fix CRITICAL/HIGH and re-run the gates.
~~~

### `project-setup/SKILL.md`
~~~markdown
---
name: project-setup
description: Adapt Claude to the current project with a private, per-project overlay (CLAUDE.local.md, .claude/settings.local.json, brain, OpenSpec in-repo or in a private store) that never touches the client repo or other projects. Use when entering a new project/repo, or when the user says "prepara este proyecto", "project setup", "adapta claude a este repo", "inicializa openspec".
---

# Project setup (private per-project overlay)

Goal: adapt Claude to the project WITHOUT leaving traces in the client repo or affecting other projects. Confirm with the user before writing.

## 1. Detect (read-only, in parallel)
- Stack and versions (manifests, lockfile), real commands (test, lint, typecheck, build), CI.
- What the team already defines: `CLAUDE.md`, `.claude/`, `AGENTS.md`, `CONTRIBUTING.md`, PR templates, commit/branch conventions, ADRs, `openspec/`.
- Databases: ORMs, `DATABASE_URL` in `.env.example`, docker-compose, db/migrate/seed scripts.
- Database MCP servers: check the repo's `.mcp.json` and `claude mcp list` (postgres, mysql, supabase, mongodb, neon, prisma, redis…).
- Ask what cannot be inferred: client constraints (what not to touch, forbidden environments, compliance), ticket tracker, language for commits/PRs.

## 2. Where specs live (ask)
- **Already has `openspec/`** → use it as is.
- **In repo** (team accepts it) → `openspec init --tools claude --scope global --language es --no-animation .`
- **Outside the repo** (private) → `openspec store setup <project-id> --path ~/openspec-stores/<project-id>`; from then on every `openspec` command uses `--store <project-id>`.
- **No SDD** (project has its own process) → follow it and record that.

## 2b. Web frontend: Modern Web Guidance (ALWAYS ask, never by default)
If the project has a web frontend, ask: "Enable Modern Web Guidance (Google Chrome) in this project for modern HTML/CSS/JS?". Only if the user says yes:
- `mkdir -p .claude/skills && cp -R ~/.claude/vendor/modern-web-guidance .claude/skills/`
- Add `.claude/skills/modern-web-guidance/` to `.git/info/exclude`.
- Add to `allow` in `settings.local.json`: `Bash(npx -y modern-web-guidance@1.0.2 search *)` and `Bash(npx -y modern-web-guidance@1.0.2 retrieve *)`.
- Note `Frontend: Modern Web Guidance enabled` in `CLAUDE.local.md`.
If the user says no, do not install it or mention it again in that project.

## 3. Write the private overlay
**`CLAUDE.local.md`** (max ~40 lines, project-specific only, do not repeat the global file):
```
# <project> — private notes
Specs: <in-repo | store: <id> (use --store <id>) | no SDD: <process>>
Stack: ...
Commands: test=…, lint=…, typecheck=…, build=…
Team conventions: branches …, commits …, PR …
Constraints: … (what must NOT be touched)
DB: <engines/environments>; forbidden: <prod, …>
@.claude/brain.md
```
**`.claude/settings.local.json`** (only the differences from global): `allow` for the project's real commands; `ask`/`deny` for project-specific DB access or scripts not covered by the global patterns; **every detected DB MCP server → `ask`** with `"mcp__<server-name>"` (covers all its tools; propose `deny` if it points to production). If it already exists, read and merge; never overwrite.

## 4. Hide without touching the repo
Append to `.git/info/exclude` (NOT `.gitignore`), with no duplicate lines: `CLAUDE.local.md`, `.claude/settings.local.json`, `.claude/brain.md` (plus in-repo specs if the team does not version them). Verify that `git status --porcelain` shows none of them.

## 4b. Brain
Create `.claude/brain.md` with the `cerebro` skill, reusing what was detected in step 1.

## 5. Baseline specs (optional, brownfield)
If the user wants: `code-explorer` lists capabilities → the user picks → `spec-miner` in parallel (one per capability, with `--store` if applicable) → `openspec validate --specs`.

## 6. Summary
3–5 lines: where specs live, which private files were created, and confirmation that `git status` is clean.
~~~

### `cerebro/SKILL.md`
~~~markdown
---
name: cerebro
description: Create, read, check and update the project's brain (.claude/brain.md) — a local, pointer-only map of what the project is, how it works and where things live, so Claude doesn't re-read the repo every session. Use when the user says "lee cerebro", "actualiza cerebro", "crea cerebro", when the SessionStart hook reports the brain missing/outdated, or after a change alters structure, flows or conventions.
---

# Project brain

`.claude/brain.md`: local, hidden via `.git/info/exclude`, imported from `CLAUDE.local.md` with the line `@.claude/brain.md`.
**Pointers only**: paths, names and a one-line explanation. Never copy code or file contents. Max ~150 lines.

## Template
```markdown
# Brain — <project>
<!-- brain: commit=<full HEAD sha> date=<YYYY-MM-DD> -->

## What it is
<2-4 lines: product, users, main stack>

## How it works
- Architecture: <layers/modules and how they talk, 3-6 lines>
- Key flows: <flow> → `path/entry` → `path/service` → `path/persistence`
- Commands: dev=… test=… lint=… build=…
- Non-obvious conventions: …

## Where
| Concept | Path |
|---|---|
| API routes | `src/...` |
| Models / DB schema | `prisma/schema.prisma` |
| Auth | `...` |
| Specs | `openspec/specs/` or store `<id>` |

## Status
- Active changes: …
- Known traps / debt: …
```

## Actions
**"lee cerebro"** (manual):
1. Read `.claude/brain.md`. If it is missing → offer to create it.
2. Check freshness: `git diff --name-only <commit> HEAD` (ignore `.claude/`).
3. Answer in ≤5 lines: status (up to date / N files changed) plus a summary. If there are many changes or the commit is missing → ask whether to re-read the project.

**Create / re-read the project** (always with the user's OK):
1. `code-explorer` maps manifests, entry points, modules, DB and config, returning paths rather than contents.
2. Fill the template with the `HEAD` commit and today's date.
3. Ensure `@.claude/brain.md` is in `CLAUDE.local.md` and `.claude/brain.md` is in `.git/info/exclude`.

**Update (incremental, no need to ask)**: after an archived change, or when touching areas the hook flagged, edit only the affected sections and bump `commit=` and `date=`. If what you find contradicts the brain, fix it right away.

## Usage rules
- Before exploring the disk, consult the brain and go straight to its paths.
- A path in the brain no longer exists → fix the brain and mention it in one line.
- Big mismatch (different structure, more than ~60 files changed) → ask: "Should I re-read the project to realign the brain?"
~~~

## Step 9: Verify the installation

```bash
ls ~/.claude/agents | wc -l                      # 14
ls ~/.claude/skills                              # sdd delivery-review project-setup cerebro + 12 openspec-* + 17 ECC
jq -e '.hooks.SessionStart' ~/.claude/settings.json
openspec --version && gh --version | head -1
```
Then tell the user to restart Claude Code and, inside their first project, say **"prepara este proyecto"**.

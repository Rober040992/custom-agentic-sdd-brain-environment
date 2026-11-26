# Rober's Agentic Environment

> A personal, tool-agnostic coding-agent setup (Claude Code today, Codex next) for professional software delivery: **Spec-Driven Development (OpenSpec) + multi-agent review + a per-project "brain" + safety rails**, adapted to each client project without leaving traces in it.

**This file has two uses:**
1. **Documentation**: what the environment is, how it is built, how and when to use it, and why.
2. **Bootstrap prompt**: give this file to any coding agent with the message *"Build this environment on my machine following the Rebuild Instructions"*. Part 2 clones the repo and runs `install.sh`; every file lives in the repo.

---

# Part 1: Overview

## What it is

A layer on top of coding agents (Claude Code, Codex…) that makes it behave like a disciplined senior engineer:

| Piece | What it does |
|---|---|
| **SDD with OpenSpec** | Every behavior change starts with a spec (proposal → requirements with scenarios → design → tasks). No code before approval. |
| **Multi-agent** | Specialist subagents explore, design, test-drive and review in parallel (in series on tools without subagents). |
| **Brain** (`.agents/brain.md`) | A per-project, pointer-only map, so the agent does not re-read the repo every session. |
| **Per-project overlay** | Private notes per project (`AGENTS.local.md`) plus each tool's local settings, hidden from git. Projects never contaminate each other. |
| **Safety rails** | Asks before any database access. Blocks secrets, force-push and merges. Auto-formats code. |

**What it is not:** an "AI factory". It is human-in-the-loop by design: you approve every spec and you decide on commits and PRs.

## Why

- **Quality over volume**: specs turn vague requests into testable scenarios; TDD and multi-agent review catch bugs before the PR.
- **Client projects differ**: a fixed global setup breaks. Here the project always wins and the global config is only a default.
- **Token economy**: the brain plus pointer-only context avoids re-reading the codebase.
- **Safety**: client databases and secrets are protected by hard rules, not by trusting the model.

## How it is built (layers)

```
custom-claude-env/  (this repo — single source of truth, symlinked into each tool)
├── core/                           TOOL-NEUTRAL
│   ├── AGENTS.md                   global working rules        → ~/.agents/AGENTS.md
│   ├── skills/                     sdd, delivery-review, project-setup, cerebro
│   │                               + 17 patterns (ECC)         → each tool's skills dir
│   ├── agents/                     14 specialist roles (ECC)
│   ├── rules/typescript, react     path-scoped language rules
│   └── vendor/modern-web-guidance  opt-in per project          → ~/.agents/vendor/
├── adapters/claude/                CLAUDE-SPECIFIC
│   ├── CLAUDE.md                   "@~/.agents/AGENTS.md" + Claude notes → ~/.claude/CLAUDE.md
│   ├── settings.json               permissions + hooks (MERGED, never linked)
│   └── hooks/                      protect-secrets, format-prettier, brain-check
├── adapters/codex/                 (phase 2)
└── install.sh                      ./install.sh --tools claude[,codex]

~/.agents/skills/openspec-*         12 official OpenSpec skills (installed by openspec)

<client-repo>/                      PER PROJECT (private, in .git/info/exclude)
├── AGENTS.local.md                 project notes: stack, commands, constraints, DB, specs store
├── .agents/brain.md                the brain
├── CLAUDE.local.md                 Claude only: "@AGENTS.local.md" + "@.agents/brain.md"
├── .claude/settings.local.json     Claude only: project permissions (DB MCP servers → ask)
└── .claude/skills/modern-web-guidance   (only if approved in setup)

~/openspec-stores/<project>/        OPTIONAL: specs kept outside the client repo
```

Precedence: **project rules / team conventions > AGENTS.local.md > global AGENTS.md**.

## When to use what

| Situation | Say | What happens |
|---|---|---|
| First time in a project | "prepara este proyecto" | `project-setup`: detect stack, choose where specs live, ask about Modern Web Guidance, create the private overlay and the brain |
| New feature / bug fix | "nuevo change: <description>" | `sdd`: explore → propose → **STOP for approval** |
| Approved spec | "implementa el change" | TDD implementation, parallel agents for `[P]` tasks |
| Finish | "cierra el change" | verify → multi-agent review → archive → update brain |
| Review a branch | "revisa la rama" | `delivery-review` (1, 2 or 5–8 reviewers, chosen with you) |
| Check project memory | "lee cerebro" | brain status and summary; asks whether to re-read the repo if it is stale |
| Typos, formatting, pure refactors | just ask | no OpenSpec needed |

## The flow

```
0. project-setup (once)  ──► AGENTS.local.md + brain.md + tool-local settings
1. "nuevo change: X"
2. Explore      code-explorer (+ architect) in parallel        0–2 agents
3. Propose      openspec-propose: proposal/specs/design/tasks  0 agents
4. ⛔ STOP      human approves the spec
5. Implement    per task: scenario → failing test → code → green
                [P] tasks → parallel agents in isolated worktrees   0–N agents
6. Verify       typecheck + lint + tests + build (really run) + openspec verify
7. Review       delivery-review: agent recommends level and asks   1 / 2 / 5–8 agents
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

Typical task: **1–9 agents total**, depending on the review level. Code itself is written by the main agent (0 agents) unless there are `[P]` tasks.

## The brain

- `.agents/brain.md`, local, at most ~150 lines, **pointers only** (paths plus one-line explanations, never copied code).
- Sections: **What it is · How it works · Where (concept → path) · Status**.
- First line stores `<!-- brain: commit=<sha> date=<date> -->`.
- Claude auto-loads it through `@.agents/brain.md` in `CLAUDE.local.md`; other tools read it per the global rule.
- The `SessionStart` hook (Claude; other tools check on demand) compares the stored commit with `HEAD`:
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
Claude: Created AGENTS.local.md, brain.md, Claude local settings, store "acme-shop".
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

# Part 2: Rebuild Instructions (for the agent)

> **Agent: follow these steps in order on macOS/Linux. `install.sh` backs up anything it replaces to `~/.agents/backups/<timestamp>/` and merges (never replaces) `~/.claude/settings.json`. Report what was installed in five lines or fewer.**

## Step 1: Prerequisites

- Node.js ≥ 22 (`nvm install 22 && nvm alias default 22`), `git`, `jq`, `gh`.
- `npm i -g @fission-ai/openspec@latest` and `openspec config set telemetry.enabled false`.

## Step 2: OpenSpec official skills (global)

```bash
openspec config set workflows '["propose","explore","new","continue","ff","apply","verify","update","sync","archive","bulk-archive","onboard"]'
openspec config set profile custom
# run inside a throwaway git repo; installs to ~/.agents/skills and links into ~/.claude/skills
mkdir -p /tmp/os-boot && cd /tmp/os-boot && git init -q \
  && OPENSPEC_TELEMETRY=0 openspec init --tools claude --scope global --language es --no-animation . \
  && cd - && rm -rf /tmp/os-boot
```

## Step 3: Clone and install

```bash
git clone https://github.com/Rober040992/custom-agentic-sdd-brain-environment.git ~/Desktop/custom-claude-env
cd ~/Desktop/custom-claude-env
./install.sh --dry-run          # preview
./install.sh --tools claude     # symlinks + settings merge
```

The repo must stay where it was cloned: the tools read it through symlinks. Edit files in the repo; changes apply at the next session.

## Step 4: Verify

- `ls -l ~/.claude/CLAUDE.md ~/.agents/AGENTS.md` → both are links into the repo.
- `ls ~/.claude/skills | wc -l` → 21 links into the repo + 12 openspec.
- `echo '{"tool_input":{"file_path":"/x/.env"}}' | ~/.claude/hooks/protect-secrets.sh` → `"deny"`.
- `claude -p "First sentence of your Databases section?"` → quotes the global rule.
- Restart the tool.

## Provenance

- `core/agents`, `core/rules` and 17 of the skills are curated from [ECC](https://github.com/affaan-m/ECC), patched: no auto-spawning reviewers, `tdd-workflow` without ECC scripts, fixed `typescript-patterns` rule paths, `spec-miner` output valid for `openspec validate`, `search-first` without the missing researcher agent.
- `core/vendor/modern-web-guidance` is [Modern Web Guidance](https://github.com/googlechrome/modern-web-guidance), pinned to `@1.0.2`.

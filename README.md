<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="agentic sdd brain: a Claude Code harness. A session shows a new change turned into a spec, a stop waiting for human approval, then implementation with all tasks, tests and review passing.">
</p>

A personal **Claude Code** setup for professional delivery on client projects. Claude writes a spec, **waits for your OK**, codes test-first, gets reviewed by parallel agents and remembers each project, all without leaving a trace in the client's repo.

## Why

- **Vague requests become testable specs.** Every change is a list of `WHEN / THEN` scenarios before any code exists.
- **You stay in control.** Nothing is implemented until you approve the spec, and nothing is committed, pushed or merged unless you ask.
- **Reviews that catch real bugs.** Up to 8 specialist reviewers run in parallel, and Claude double-checks every serious finding.
- **No re-reading the repo every session.** A per-project *brain* maps what the project is, how it works and where things live.
- **Every client is different.** The project's own rules always win; this setup is only the default.

## How a task flows

<p align="center">
  <img src="./assets/readme/workflow.svg" width="100%" alt="Flow of one task: explore with 0–2 agents, write the spec with OpenSpec, human approval gate, code test-first, verify with real lint and tests, review with 1, 2 or 5–8 agents chosen with you, then archive and update the brain.">
</p>

The code itself is written by the main Claude, which has the full context. Agents are used where an independent view helps: exploring, parallel `[P]` tasks and review.

## Daily use

| Say | What happens |
|---|---|
| `prepara este proyecto` | One-time setup: stack, specs location, brain, private config |
| `nuevo change: <idea>` | Explore → spec → **stops for your approval** |
| `implementa el change` | Task by task: failing test → code → green |
| `cierra el change` | Verify → review → archive → update the brain |
| `revisa la rama` | Review of the current branch at a level you choose |
| `lee cerebro` | Project memory: status and summary |

## What's inside

| | |
|---|---|
| 📐 **OpenSpec** | Spec-Driven Development: proposal, scenarios, design, tasks |
| 🤖 **14 agents** | Explorer, architect, TDD guide, build fixers and 8 reviewers |
| 🧠 **Brain** | `.claude/brain.md`: pointers only, freshness checked against git on every session start |
| 🧩 **Private overlay** | `CLAUDE.local.md` + `settings.local.json`, hidden through `.git/info/exclude` |
| 🛡️ **Safety rails** | Asks before any DB access (CLI or MCP) · blocks secrets, force-push and merges · auto-format |

```
~/.claude/       global defaults: rules, agents, skills, hooks
<project>/       CLAUDE.md + team conventions        ← always wins
<project>/       CLAUDE.local.md · .claude/brain.md  ← private, never committed
```

## Rebuild it anywhere

Give [`docs/rober-agentic-environment.md`](docs/rober-agentic-environment.md) to any Claude Code session and say:

> *Build this environment on my machine following the Rebuild Instructions.*

It contains the full explanation and every file verbatim.

## Limits

- Brain freshness is tracked against git commits and uncommitted files, not editor buffers.
- DB protection is pattern-based: custom scripts with unusual names rely on the written rule, not on a hard block.
- Built for a TypeScript / React / Node default stack; other stacks use the project's own rules.

---

<sub>Built on [OpenSpec](https://github.com/Fission-AI/OpenSpec) · curated parts of [ECC](https://github.com/affaan-m/ECC) · [Modern Web Guidance](https://github.com/googlechrome/modern-web-guidance) (opt-in) · README visuals made following [beautify-github-readme](https://github.com/oil-oil/beautify-github-readme)</sub>

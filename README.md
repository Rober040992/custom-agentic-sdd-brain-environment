# 🧠 Rober's Agentic Harness

**A personal Claude Code setup that works like a disciplined senior engineer.**
Specs first, tests first, parallel reviews, and a per-project memory, adapted to each client project without leaving a trace in it.

```
spec ──► ⛔ approval ──► TDD code ──► verify ──► multi-agent review ──► archive
```

---

## ✨ What's inside

| | Piece | Purpose |
|---|---|---|
| 📐 | **SDD with OpenSpec** | Every change starts as a spec with testable scenarios. No code before you approve it. |
| 🤖 | **14 specialist agents** | Explore, design, test-drive and review, in parallel when it pays off. |
| 🧠 | **Project brain** | `.claude/brain.md`: a pointer-only map, so Claude doesn't re-read the repo every session. |
| 🧩 | **Per-project overlay** | Private `CLAUDE.local.md` + `settings.local.json`, hidden from git. Projects never mix. |
| 🛡️ | **Safety rails** | Asks before any DB access · blocks secrets, force-push and merges · auto-formats. |

## 🚀 Daily use

| Say | What happens |
|---|---|
| `prepara este proyecto` | One-time setup: stack, specs location, brain, private config |
| `nuevo change: <idea>` | Explore → spec → **stops for your approval** |
| `implementa el change` | Task by task: failing test → code → green |
| `cierra el change` | Verify → review (1, 2 or 5–8 agents, you choose) → archive |
| `revisa la rama` | Multi-agent review of the current branch |
| `lee cerebro` | Project memory status and summary |

## 🏗️ How it's layered

```
~/.claude/          global defaults (rules, agents, skills, hooks)
   ▲ overridden by
<project>/          CLAUDE.md + team conventions   (theirs, untouched)
   ▲ extended by
<project>/          CLAUDE.local.md · .claude/settings.local.json · .claude/brain.md
                    (mine, hidden via .git/info/exclude)
```

**The project always wins.** The global config is just a sensible default.

## 🔁 Rebuild anywhere

Give **`rober-agentic-environment.md`** to any Claude Code session:

> *Build this environment on my machine following the Rebuild Instructions.*

It contains the full explanation and every file verbatim.

## 🧱 Built on

[OpenSpec](https://github.com/Fission-AI/OpenSpec) · curated parts of [ECC](https://github.com/affaan-m/ECC) · [Modern Web Guidance](https://github.com/googlechrome/modern-web-guidance) (opt-in per project)

---

<sub>Personal setup · local-only repo · human-in-the-loop by design</sub>

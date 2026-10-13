# AI Skills — Team Engineering Workflows for Coding Agents

Portable, host-agnostic skill pack for AI coding agents (GitHub Copilot, Claude Code, Cursor, Codex, Gemini CLI, and any agent that reads Markdown instructions). It standardizes how the team specs, plans, builds, tests, reviews, and ships software with agents.

Based on [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT — see `LICENSE.agent-skills`), with local additions and adaptations.

## What's in here

```
ai-skills/
├── skills/        ← 26 SKILL.md workflows (the core; plain Markdown, portable)
├── agents/        ← 4 reviewer personas (code-reviewer, test-engineer, security-auditor, web-performance-auditor)
├── references/    ← shared checklists skills link to (definition-of-done, testing, security, a11y, perf, observability)
└── README.md      ← you are here
```

Start with **`skills/using-agent-skills/SKILL.md`** — it's the router that maps any incoming task to the right skill.

### The lifecycle

| Phase | Key skills |
|---|---|
| Define | `interview-me`, `idea-refine`, `spec-driven-development`, `constraint-driven-development` |
| Plan | `planning-and-task-breakdown` |
| Build | `incremental-implementation`, `test-driven-development`, `frontend-ui-engineering`, `backend-and-data`, `api-and-interface-design`, `context-engineering`, `source-driven-development`, `doubt-driven-development` |
| Verify | `browser-testing-with-devtools`, `debugging-and-error-recovery` |
| Review | `code-review-and-quality`, `code-simplification`, `security-and-hardening`, `performance-optimization` |
| Ship | `git-workflow-and-versioning`, `ci-cd-and-automation`, `documentation-and-adrs`, `observability-and-instrumentation`, `deprecation-and-migration`, `shipping-and-launch` |

## Installation

Skills are plain Markdown — "installing" means putting them where your agent discovers them.

### GitHub Copilot (CLI / IDE)
- **Per-repo:** copy the skill folders you want into the repo's `.github/skills/` (and `references/` into `.github/references/` — skills link to `../../references/`).
- **Personal (all repos):** copy or symlink into `~/.copilot/skills/`.

### Claude Code
- Copy skill folders into `~/.claude/skills/` (global) or `.claude/skills/` (per project).
- Personas in `agents/` can be added as custom subagents.

### Cursor
- Sync `skills/` into `.cursor/skills/` in your project; keep short policies in `.cursor/rules/*.mdc`.

### Codex / Gemini CLI / others
- Point the tool's skill-discovery at `skills/`, or paste a `SKILL.md` as instructions. Any agent that accepts instruction files can use these.

> **Keep paths intact:** several skills reference `../../references/<checklist>.md`. If you copy an individual skill, also copy `references/` two levels up from the skill folder, or adjust the link.

## Change sizing — when to apply the full process

These workflows are **defaults, scaled to the size of the change** — not bureaucracy for one-liners:

| Change | Process |
|---|---|
| Trivial (typo, config value, one-line fix) | Skip spec/plan. Test + commit with a clear message. |
| Small (single-file bug fix, minor tweak) | Skip spec. TDD + review before merge. |
| Medium (feature touching a few files) | Lightweight spec (a paragraph of acceptance criteria) → plan → incremental build → test → review. |
| Large (new feature, refactor, migration) | Full lifecycle: spec → plan → build → test → review → ship. |

When in doubt, the skill's own "When to Use" section decides. An agent that invokes the full lifecycle for a typo is misrouting — see `skills/using-agent-skills/SKILL.md`.

## Conventions

- Every skill follows the same anatomy: frontmatter → Overview → When to Use → Process → Rationalization table → Red Flags → Verification.
- Verification is non-negotiable: evidence (tests passing, build output, runtime data), never "seems right".
- New skills must follow the same anatomy and be referenced from `using-agent-skills` if they should be routable.

## Attribution

Upstream skills © Addy Osmani and contributors, MIT license (`LICENSE.agent-skills`). Local modifications and additions by the Progressive Leasing team.

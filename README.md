# Obsidian Task Tracker

**Stop context-switching between your code editor, project manager, and notes app.** This is a local-first task management system that lives where you already work — your terminal and your text editor. Plain markdown files, zero cloud dependencies, full AI automation.

Built on [Obsidian](https://obsidian.md) with support for both [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and OpenAI Codex. Inspired by the [Teresa Torres pattern](https://creatoreconomy.so/p/automate-your-life-with-claude-code-teresa-torres): one file per task, YAML frontmatter as the schema, assistant-facing config in-repo, Obsidian as the UI.

---

## The problem

You're juggling 3-5 projects. Tasks live in Linear, Notion, GitHub Issues, sticky notes, and your head. You lose 20 minutes a day just figuring out *what to work on next*. At the end of the week you can't remember what you actually shipped.

## The solution

Your tasks are markdown files on disk. Claude Code manages them with slash commands, while Codex Agent uses `AGENTS.md` plus `/skills:<name>` entries registered from this repo's `.claude/commands/`. Obsidian renders live dashboards automatically. Git tracks everything. No accounts, no sync issues, no subscription.

```
Obsidian (think/plan)  ->  Agent command  ->  Task Tracker  ->  Repo work
                                |                                  |
                    Claude: /task /done /today               Git activity
                    Codex:  /skills:task /skills:done
```

- **Tasks** are markdown files with YAML frontmatter in `tasks/<project>/`
- **Obsidian** renders dashboards, kanban boards, and analytics via Dataview queries
- **Claude Code** reads and writes task files via slash commands and `CLAUDE.md`
- **OpenAI Codex Agent** uses `AGENTS.md`, `setup-codex.sh`, `refresh-codex-skills.sh`, and skills registered into `~/.agents/skills`
- **Git** tracks all changes — obsidian-git plugin auto-syncs to your private repo

---

## Agent surfaces

| Environment | Trigger style | Source of truth | Install step |
|-------------|---------------|-----------------|--------------|
| **Claude Code** | `/task`, `/done`, `/today` | `.claude/commands/` + `CLAUDE.md` | `./setup-claude.sh` |
| **Codex Agent** | `/skills:task`, `/skills:done`, `/skills:today` | `.claude/commands/` + `AGENTS.md` | `./setup-codex.sh` |

Both agents operate on the same markdown vault, the same project files, and the same task files.

---

## What a day looks like

**Morning** — open your terminal, run one command:

```bash
# Claude Code
/today

# Codex Agent
/skills:today
```

The active agent scans all your tasks, checks git history across every project, and generates today's daily note:
- What's due today
- What's overdue
- What's in progress
- Suggested top 3 priorities

**During work** — stay in your flow:

```bash
# Claude Code
/task "Fix auth timeout" --project myapp --priority high --effort 2h
/done APP-017 --actual 1h

# Codex Agent
/skills:task "Fix auth timeout" --project myapp --priority high --effort 2h
/skills:done APP-017 --actual 1h
```

Tasks get created with auto-incremented IDs, filed in the right folder. Completed tasks update timestamps, log effort, and unblock dependent work. You never leave the terminal.

**End of day** — one command wraps everything up:

```bash
# Claude Code
/review

# Codex Agent
/skills:review
```

The active agent counts what you completed, updates your daily note, appends to the burndown log, and suggests what to focus on tomorrow.

**Weekly** — see the big picture:

```bash
# Claude Code
/pulse

# Codex Agent
/skills:pulse
```

Cross-project health report: active/blocked/overdue per project, git activity, health status. Know instantly which project needs attention.

---

## Quick start

**1. Clone into the folder you want to use**

```bash
# Example: install the tracker into ~/project-board
git clone https://github.com/ignatpenshin/obsidian-task-tracker.git ~/project-board
cd ~/project-board
```

This repository becomes your tracker vault in that exact folder. The setup script initializes the tracker there.

**2. Choose your setup path**

```bash
# Claude Code environment
./setup-claude.sh

# Codex Agent environment
./setup-codex.sh
```

The setup scripts ask for your project names, create the shared vault folders, configure the assistant-facing root files, and can initialize git. `setup-codex.sh` also detects Linux, macOS, or Windows and registers Codex skills in your user `~/.agents/skills` directory by symlinking them to this repo's `.claude/commands/`.

If you later add, rename, or remove files in `.claude/commands/`, run:

```bash
./refresh-codex-skills.sh
```

Both setup scripts prompt for the same project metadata:
- project name
- display name
- ID prefix
- optional git repo path for the real working project

Example:
- task tracker installed at `~/project-board`
- working repo for your app at `/home/you/work/myapp`
- when setup asks for `Git repo path`, enter `/home/you/work/myapp`

You can also run Codex setup non-interactively:

```bash
./setup-codex.sh --project myapp --display-name "My App" --prefix APP --repo /home/you/work/myapp
```

**3. Open in Obsidian**

Open the folder as a vault. Install these community plugins:

| Plugin | Why |
|--------|-----|
| **Dataview** | Powers every dashboard and query |
| **Templater** | Template engine for daily/weekly notes |
| **Periodic Notes** | Auto-creates daily and weekly notes from templates |
| **Calendar** | Sidebar date picker linked to daily notes |
| **Kanban** | Drag-and-drop board view for tasks |
| **obsidian-git** | Auto-commit and push to your private repo |

Configure Templater (template folder → `templates/`, enable system commands) and Periodic Notes (daily folder `daily/`, weekly folder `weekly/` — see [plugin config](#plugin-configuration) below).

**4. Manage projects**

```bash
./add-project.sh --name myapp --display-name "My App" --prefix APP --repo /home/you/work/myapp
./remove-project.sh --name myapp
```

These scripts keep both `CLAUDE.md` and `AGENTS.md` in sync with the shared project registry.
Use `--repo` to link the task-tracker project to the absolute path of the real working repository whose git activity should be tracked.

### Typical workflow

Example:
- task tracker installed at `~/project-board`
- first working repository at `/home/you/work/myapp`
- second working repository at `/home/you/work/api`

```bash
git clone https://github.com/ignatpenshin/obsidian-task-tracker.git ~/project-board
cd ~/project-board

# Choose one setup path
./setup-claude.sh
# or
./setup-codex.sh

# When prompted for the first project, enter:
# Project name: myapp
# Display name: My App
# ID prefix: APP
# Git repo path: /home/you/work/myapp

# Add another linked project later
./add-project.sh --name api --display-name "API Service" --prefix API --repo /home/you/work/api

# Remove a project from both assistant environments
./remove-project.sh --name api
```

**5. Start working**

```bash
# Claude Code
/task "Build landing page" --project myapp --priority high --due 2025-02-01 --effort 4h

# Codex Agent
/skills:task "Build landing page" --project myapp --priority high --due 2025-02-01 --effort 4h
```

For Codex Agent, run `./setup-codex.sh` once, restart Codex, and use the registered skills `task`, `done`, `today`, `review`, `plan`, `pulse`, `import`, and `sync`.
Those skills are registered in `~/.agents/skills`, but their `SKILL.md` files are symlinks back to this repository's `.claude/commands/`, so the source of truth stays in the project.
After changing `.claude/commands/`, run `./refresh-codex-skills.sh` and restart Codex.

Open Obsidian — the dashboard already shows your project/task files.

---

## Workflow commands

The same workflow is available in both agents. Claude uses direct slash commands. Codex Agent uses the same prompt source through `/skills:<name>`.

### Daily workflow

| Claude Code | Codex Agent | What it does |
|-------------|-------------|--------------|
| `/today` | `/skills:today` | Generate today's daily note with due tasks, overdue items, git activity, suggested priorities |
| `/review` | `/skills:review` | End-of-day summary: count completions, update burndown log, suggest tomorrow's focus |
| `/plan` | `/skills:plan` | Plan tomorrow (`plan`) or next week (`plan week`) based on due dates and priorities |
| `/pulse` | `/skills:pulse` | Cross-project health report: active/blocked/overdue per project, git activity, health status |

### Task management

| Claude Code | Codex Agent | What it does |
|-------------|-------------|--------------|
| `/task <title> --project X --priority high` | `/skills:task <title> --project X --priority high` | Create a new task with auto-incremented ID |
| `/done TASK-ID` | `/skills:done TASK-ID` | Mark task completed, update timestamps, check for unblocked tasks |
| `/sync` | `/skills:sync` | Fetch latest git activity across all project repos |
| `/import /path/to/plan.md --project X` | `/skills:import /path/to/plan.md --project X` | Import a list or feature plan as individual tasks |

### Examples

```bash
# Morning in Claude Code
/today

# Morning in Codex Agent
/skills:today

# Create tasks as they come up in Claude Code
/task "Add rate limiting" --project api --priority high --due 2025-03-01 --effort 2h
/task "Update onboarding copy" --project web --priority low

# Create tasks as they come up in Codex Agent
/skills:task "Add rate limiting" --project api --priority high --due 2025-03-01 --effort 2h
/skills:task "Update onboarding copy" --project web --priority low

# Finish work in Claude Code
/done API-003 --actual 3h

# Finish work in Codex Agent
/skills:done API-003 --actual 3h

# Import a big feature plan at once in Claude Code
/import ~/notes/feature-plan.md --project api

# Import a big feature plan at once in Codex Agent
/skills:import ~/notes/feature-plan.md --project api

# End of day in Claude Code
/review

# End of day in Codex Agent
/skills:review

# Weekly health check in Claude Code
/pulse

# Weekly health check in Codex Agent
/skills:pulse
```

---

## How it's structured

```
my-tasks/
├── dashboard.md              # Live Dataview-powered overview
├── projects/                 # One file per project (metadata + queries)
│   └── myapp.md
├── tasks/                    # One file per task, organized by project
│   └── myapp/
│       ├── build-landing-page.md
│       └── fix-auth-timeout.md
├── daily/2025/01/            # Daily notes (auto-generated)
├── weekly/2025/              # Weekly notes
├── templates/                # Templater templates (daily, weekly, task, project)
├── kanban/                   # Kanban board
├── analytics/                # Burndown log (appended by /review)
├── archive/                  # Completed tasks you want out of the way
├── .claude/commands/         # Source of truth for Claude commands and Codex skill prompts
├── AGENTS.md                 # Codex config: vault path, project table, conventions
└── CLAUDE.md                 # Claude config: vault path, project table, conventions
```

Codex registration model:
- project prompts stay in `.claude/commands/`
- `setup-codex.sh` creates wrapper skill folders in `~/.agents/skills`
- each wrapper skill contains `SKILL.md -> <repo>/.claude/commands/<name>.md`
- `refresh-codex-skills.sh` re-syncs that registry after command changes
- Codex picks up the user-level skill registry after restart

### Task file format

Each task is a standalone markdown file:

```yaml
---
id: APP-003
title: Add rate limiting
status: todo              # todo | in-progress | done | blocked | cancelled
project: api
priority: high            # high | medium | low
due: 2025-03-01
tags: [backend, security]
created: 2025-01-20
completed:
blocked_by:
effort: 2h                # 30m, 1h, 2h, 4h, 1d, 2d, 1w
actual:
---

## Description
Add rate limiting to public API endpoints.

## Acceptance Criteria
- [ ] Rate limit by API key
- [ ] Return 429 with retry-after header
- [ ] Dashboard shows rate limit hits

## Log
- 2025-01-20: Created
```

### Dashboard

`dashboard.md` renders live Dataview queries — no manual updates needed:

- Active tasks by project (todo / in-progress / blocked / done counts)
- Overdue items
- Due this week
- High priority backlog
- Recently completed (last 7 days)
- Blocked items with dependency info
- Project health overview
- Weekly velocity (last 8 weeks)

---

## Adding projects

Run `./add-project.sh`, `./remove-project.sh`, `./setup-claude.sh`, or `./setup-codex.sh` as appropriate, or manage the files manually:

1. Create `projects/<name>.md` with frontmatter (id_prefix, next_id, repo path)
2. Create `tasks/<name>/` directory
3. Add the project to the table in `CLAUDE.md`
4. Add the project to the table in `AGENTS.md`
5. If you changed `.claude/commands/`, run `./refresh-codex-skills.sh`

### Connecting a project repo

Add a note to the `CLAUDE.md` in any project repo so Claude knows about the tracker:

```markdown
## Task Tracker
Tasks tracked at /path/to/my-tasks/tasks/<project>/.
Run /sync at session start, /done when finishing work.
```

This makes Claude aware of your task tracker in every dev session.

---

## Plugin configuration

**Templater**
- Template folder: `templates/`
- Enable "Trigger on new file creation"
- Enable "System commands" (needed for git activity in daily notes)

**Periodic Notes**
- Daily: folder `daily/{{date:YYYY}}/{{date:MM}}`, format `{{date:YYYY-MM-DD}}`, template `templates/daily-template.md`
- Weekly: folder `weekly/{{date:YYYY}}`, format `{{date:YYYY-[W]WW}}`, template `templates/weekly-template.md`

**Homepage** (optional): set to `dashboard`

---

## Design principles

- **Local-first** — plain markdown on your disk, works offline, no accounts
- **Git-native** — every change is tracked, diffable, mergeable
- **No lock-in** — works without Claude Code (just slower), works without Obsidian (just less pretty)
- **Convention over configuration** — file names, frontmatter schema, and folder structure are the database

## Requirements

- [Obsidian](https://obsidian.md) (free)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (for slash commands)
- OpenAI Codex Agent (for `AGENTS.md` + `/skills:<name>` workflow)
- Git

## License

MIT

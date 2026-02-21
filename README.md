# Obsidian Task Tracker

**Stop context-switching between your code editor, project manager, and notes app.** This is a local-first task management system that lives where you already work — your terminal and your text editor. Plain markdown files, zero cloud dependencies, full AI automation.

Built on [Obsidian](https://obsidian.md) + [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Inspired by the [Teresa Torres pattern](https://creatoreconomy.so/p/automate-your-life-with-claude-code-teresa-torres): one file per task, YAML frontmatter as the schema, Claude Code slash commands as the API, Obsidian as the UI.

---

## The problem

You're juggling 3-5 projects. Tasks live in Linear, Notion, GitHub Issues, sticky notes, and your head. You lose 20 minutes a day just figuring out *what to work on next*. At the end of the week you can't remember what you actually shipped.

## The solution

Your tasks are markdown files on disk. You manage them from the terminal with one-word commands. Obsidian renders live dashboards automatically. Git tracks everything. No accounts, no sync issues, no subscription.

```
Obsidian (think/plan)  →  /import  →  Task Tracker  →  /sync  →  Dev Session
                                            ↑                         |
                                        /today /plan              /done /task
                                            ↑                         |
                                        /review  ←────────────────────┘
```

- **Tasks** are markdown files with YAML frontmatter in `tasks/<project>/`
- **Obsidian** renders dashboards, kanban boards, and analytics via Dataview queries
- **Claude Code** reads and writes task files from any terminal via slash commands
- **Git** tracks all changes — obsidian-git plugin auto-syncs to your private repo

---

## What a day looks like

**Morning** — open your terminal, run one command:

```bash
/today
```

Claude scans all your tasks, checks git history across every project, and generates today's daily note:
- What's due today
- What's overdue
- What's in progress
- Suggested top 3 priorities

**During work** — stay in your flow:

```bash
/task "Fix auth timeout" --project myapp --priority high --effort 2h
/done APP-017 --actual 1h
```

Tasks get created with auto-incremented IDs, filed in the right folder. Completed tasks update timestamps, log effort, and unblock dependent work. You never leave the terminal.

**End of day** — one command wraps everything up:

```bash
/review
```

Claude counts what you completed, updates your daily note, appends to the burndown log, and suggests what to focus on tomorrow.

**Weekly** — see the big picture:

```bash
/pulse
```

Cross-project health report: active/blocked/overdue per project, git activity, health status. Know instantly which project needs attention.

---

## Quick start

**1. Clone and run setup**

```bash
git clone https://github.com/ignatpenshin/obsidian-task-tracker.git my-tasks
cd my-tasks
./setup.sh
```

The script asks for your project names, creates all the folders and config, and initializes git. Takes 30 seconds.

**2. Open in Obsidian**

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

**3. Create your first task**

```bash
/task "Build landing page" --project myapp --priority high --due 2025-02-01 --effort 4h
```

Open Obsidian — the dashboard already shows it.

---

## Slash commands

### Daily workflow

| Command | What it does |
|---------|-------------|
| `/today` | Generate today's daily note with due tasks, overdue items, git activity, suggested priorities |
| `/review` | End-of-day summary: count completions, update burndown log, suggest tomorrow's focus |
| `/plan` | Plan tomorrow (`/plan`) or next week (`/plan week`) based on due dates and priorities |
| `/pulse` | Cross-project health report: active/blocked/overdue per project, git activity, health status |

### Task management

| Command | What it does |
|---------|-------------|
| `/task <title> --project X --priority high` | Create a new task with auto-incremented ID |
| `/done TASK-ID` | Mark task completed, update timestamps, check for unblocked tasks |
| `/sync` | Fetch latest git activity across all project repos |
| `/import /path/to/plan.md --project X` | Import a list or feature plan as individual tasks |

### Examples

```bash
# Morning
/today

# Create tasks as they come up
/task "Add rate limiting" --project api --priority high --due 2025-03-01 --effort 2h
/task "Update onboarding copy" --project web --priority low

# Finish work
/done API-003 --actual 3h

# Import a big feature plan at once
/import ~/notes/feature-plan.md --project api

# End of day
/review

# Weekly health check
/pulse
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
├── .claude/commands/         # The 8 slash commands
└── CLAUDE.md                 # Config: vault path, project table, conventions
```

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

Run `./setup.sh` again, or manually:

1. Create `projects/<name>.md` with frontmatter (id_prefix, next_id, repo path)
2. Create `tasks/<name>/` directory
3. Add the project to the table in `CLAUDE.md`

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
- Git

## License

MIT

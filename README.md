# Obsidian Task Tracker

A local-first task management system built on [Obsidian](https://obsidian.md) and [Claude Code](https://claude.ai/claude-code). Track tasks across multiple projects using plain markdown files with YAML frontmatter, Dataview queries for dashboards, and Claude Code slash commands for automation.

## How It Works

```
You (in terminal)                 Obsidian (always open)
    |                                  |
    |  /task Fix login bug             |
    |  --project myapp                 |
    |  --priority high                 |
    |                                  |
    v                                  v
Claude Code                    Dataview auto-refreshes
  - creates tasks/myapp/          - dashboard updates
    fix-login-bug.md              - kanban board updates
  - assigns ID APP-001            - project view updates
  - increments next_id
    |
    |  /today
    v
  - creates daily/2025/01/
    2025-01-15.md
  - lists due & overdue tasks
  - fetches git activity
    |
    |  /done APP-001
    v
  - marks task done
  - checks for unblocked tasks
  - logs completion
    |
    |  /review
    v
  - updates daily note summary
  - appends burndown metrics
  - suggests tomorrow's focus
```

## Quick Start

### 1. Clone and set up

```bash
git clone https://github.com/YOUR_USERNAME/obsidian-task-tracker.git my-tasks
cd my-tasks
chmod +x setup.sh
./setup.sh
```

The setup script will ask for your project names and configure everything.

### 2. Open in Obsidian

Open the folder as an Obsidian vault, then install these community plugins:

| Plugin | Purpose |
|--------|---------|
| **Dataview** | Powers all dashboards and queries |
| **Templater** | Template engine for daily/weekly/task notes |
| **Periodic Notes** | Auto-creates daily and weekly notes |
| **Calendar** | Visual calendar for daily notes |
| **Kanban** | Board view for tasks |
| **Tasks** | Checkbox tracking across files |

#### Plugin configuration

- **Templater**: Set template folder to `templates/`. Enable system commands if you want git activity in daily notes.
- **Periodic Notes**: Daily format `YYYY/MM/YYYY-MM-DD`, folder `daily/`. Weekly format `YYYY/YYYY-[W]WW`, folder `weekly/`.
- **Dataview**: Enable JavaScript queries (for advanced dashboards).

### 3. Start tracking

```bash
# Create a task
claude /task "Build landing page" --project myapp --priority high --due 2025-02-01 --effort 4h

# Start your day
claude /today

# Mark tasks done
claude /done APP-001

# End-of-day review
claude /review

# Cross-project health check
claude /pulse
```

## Slash Commands

| Command | Description |
|---------|-------------|
| `/task` | Create a new task with auto-generated ID |
| `/done` | Mark a task as completed |
| `/today` | Generate or update today's daily note |
| `/plan` | Plan tomorrow or next week |
| `/review` | End-of-day review with metrics |
| `/pulse` | Cross-project health report |
| `/sync` | Sync git activity across all project repos |
| `/import` | Import tasks from an external list or document |

## Directory Structure

```
vault/
├── CLAUDE.md              # Config: vault path, project table, conventions
├── dashboard.md           # Main Dataview dashboard
├── tasks/
│   └── <project>/         # Task files with YAML frontmatter
├── projects/
│   └── <project>.md       # Project metadata + Dataview queries
├── daily/
│   └── YYYY/MM/           # Daily notes
├── weekly/
│   └── YYYY/              # Weekly notes
├── templates/             # Templater templates
├── kanban/                # Kanban board files
├── analytics/             # Burndown logs
├── archive/               # Completed tasks
└── .claude/commands/      # Claude Code slash commands
```

## Task File Format

Each task is a markdown file with YAML frontmatter:

```yaml
---
id: APP-001
title: Build landing page
status: todo          # todo | in-progress | done | blocked | cancelled
project: myapp
priority: high        # high | medium | low
due: 2025-02-01
tags: [frontend, launch]
created: 2025-01-15
completed:
blocked_by:
effort: 4h            # 30m, 1h, 2h, 4h, 1d, 2d, 1w
actual:
---
```

## Adding a New Project

1. Create `projects/<name>.md` with the required frontmatter (use the project template)
2. Create `tasks/<name>/` directory
3. Add the project to the table in `CLAUDE.md`
4. Start creating tasks with `/task --project <name>`

Or re-run `./setup.sh` to add projects interactively.

## Design Principles

- **Local-first**: Everything is plain markdown files on your disk
- **Git-friendly**: All files are diffable, mergeable text
- **No lock-in**: Works without Claude Code (just slower). Works without Obsidian (just less pretty)
- **Convention over configuration**: File naming, frontmatter schema, and folder structure are the "database"

## Requirements

- [Obsidian](https://obsidian.md) (free)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (for slash commands)
- Git (for version control and sync)

## License

MIT

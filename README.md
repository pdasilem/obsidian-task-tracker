# Obsidian Task Tracker

**Stop context-switching between your code editor, project manager, and notes app.** This is a local-first task management system that lives where you already work: your terminal and your text editor. Plain markdown files, zero cloud dependencies, full AI automation.

Built on [Obsidian](https://obsidian.md) with support for both Claude Code and OpenAI Codex. Inspired by the [Teresa Torres pattern](https://creatoreconomy.so/p/automate-your-life-with-claude-code-teresa-torres): one file per task, YAML frontmatter as the schema, assistant-facing config in-repo, Obsidian as the UI.

---

## The problem

You're juggling 3..5 projects. Tasks live in Jira, chat threads, issue trackers, sticky notes, and your head. You 
lose time every day just figuring out what to work on next. At the end of the week you can't remember what you actually shipped.

## The solution

Your tasks are markdown files on disk. The agent manages them with slash commands. Obsidian renders live dashboards automatically. Git tracks everything.

```
Obsidian (think/plan)  ->  Agent command  ->  Task Tracker  ->  Repo work
                                |                                  |
                        /task /done /today                   Git activity
                                |
                   Codex: add the `skills:` prefix
```

- **Tasks** live in `tasks/<project>/` as markdown files with YAML frontmatter.
- **Obsidian** renders dashboards, kanban boards, and analytics via Dataview queries.
- **Claude Code** uses `.claude/commands/` and `CLAUDE.md`.
- **Codex Agent** uses the same command prompts copied into `~/.agents/skills/<name>/SKILL.md` plus `AGENTS.md`.
- **Git** tracks all changes and can be auto-synced from Obsidian if you want.

---

## Command rule

Use the commands exactly as shown below in Claude Code.

If you use Codex Agent, add the `skills:` prefix to the command name:
- Claude Code: `/done APP-003`
- Codex Agent: `/skills:done APP-003`

That rule applies to all workflow commands:
- `/today`
- `/review`
- `/plan`
- `/pulse`
- `/task`
- `/done`
- `/sync`
- `/import`
- `/jira-push`

---

## What a day looks like

**Morning**

```bash
/today
```

The agent scans all your tasks, checks git history across every project, and generates today's daily note:
- what's due today
- what's overdue
- what's in progress
- suggested top 3 priorities

**During work**

```bash
/task "Fix auth timeout" --project myapp --priority high --effort 2h
/task https://your-company.atlassian.net/browse/APP-42 --project myapp --priority high
/done APP-017 --actual 1h
```

Tasks get created with auto-incremented local IDs, filed in the right folder, and updated in place. If `/task` receives a Jira issue URL and Jira MCP integration is available, it pulls the Jira title and description into the tracker task.

**End of day**

```bash
/review
```

**Weekly**

```bash
/pulse
```

---

## Quick start

**1. Clone into the folder you want to use**

```bash
git clone https://github.com/ignatpenshin/obsidian-task-tracker.git ~/project-board
cd ~/project-board
```

This repository becomes your tracker vault in that exact folder.

**2. Choose your setup path**

```bash
# Claude Code
./setup-claude.sh

# Codex Agent
./setup-codex.sh
```

Both setup scripts ask for the same project metadata:
- project name
- display name
- ID prefix
- optional git repo path for the real working project

Example:
- tracker installed at `~/project-board`
- working repo at `/home/you/work/myapp`
- when prompted for `Git repo path`, enter `/home/you/work/myapp`

Codex-only note:
- `setup-codex.sh` detects Linux, macOS, or Windows
- it copies prompts from `.claude/commands/` into `~/.agents/skills/<name>/SKILL.md`
- it rewrites `CLAUDE.md` to `AGENTS.md`
- it rewrites `/command` to `/skills:command`

If you later add or change files in `.claude/commands/`, run:

```bash
./refresh-codex-skills.sh
```

Then restart Codex.

**3. Open in Obsidian**

Open the folder as a vault. Install these community plugins:

| Plugin             | Why                                                |
|--------------------|----------------------------------------------------|
| **Dataview**       | Powers every dashboard and query                   |
| **Templater**      | Template engine for daily and weekly notes         |
| **Periodic Notes** | Auto-creates daily and weekly notes from templates |
| **Calendar**       | Sidebar date picker linked to daily notes          |
| **Kanban**         | Drag-and-drop board view for tasks                 |
| **obsidian-git**   | Auto-commit and push to your private repo          |

Configure:
- Templater: template folder `templates/`, enable system commands
- Periodic Notes daily: folder `daily/`, weekly: folder `weekly/`

**4. Manage projects**

```bash
./add-project.sh --name myapp --display-name "My App" --prefix APP --repo /home/you/work/myapp
./remove-project.sh --name myapp
```

These scripts keep `CLAUDE.md` and `AGENTS.md` in sync with the shared project registry.

**5. Start working**

```bash
/task "Build landing page" --project myapp --priority high --due 2025-02-01 --effort 4h
```

If you use Codex Agent:

```bash
/skills:task "Build landing page" --project myapp --priority high --due 2025-02-01 --effort 4h
```

Open Obsidian and the dashboard already shows your project and task files.

---

## Workflow commands

### Daily workflow

| Command   | What it does                                                                                      |
|-----------|---------------------------------------------------------------------------------------------------|
| `/today`  | Generate today's daily note with due tasks, overdue items, git activity, and suggested priorities |
| `/review` | End-of-day summary: count completions, update burndown log, suggest tomorrow's focus              |
| `/plan`   | Plan tomorrow or next week based on due dates and priorities                                      |
| `/pulse`  | Cross-project health report: active, blocked, overdue per project, git activity, health status    |

### Task management

| Command                                        | What it does                                                                                              |
|------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `/task <title> --project X --priority high`    | Create a new local task with an auto-incremented tracker ID                                               |
| `/task <jira-url> --project X --priority high` | Fetch a Jira issue through MCP, prepend the Jira key to the local title, and create a linked tracker task |
| `/done TASK-ID`                                | Mark a task completed, update timestamps, check for unblocked tasks                                       |
| `/sync`                                        | Fetch latest git activity across all project repos                                                        |
| `/import /path/to/plan.md --project X`         | Parse a note, list, or feature plan and decompose it into individual task files                           |
| `/jira-push TASK-ID`                           | Create a Jira issue from an existing local task and write back the Jira key and URL                       |

### Examples

```bash
/today
/task "Add rate limiting" --project api --priority high --due 2025-03-01 --effort 2h
/task https://your-company.atlassian.net/browse/API-42 --project api --priority high
/done API-003 --actual 3h
/import ~/notes/feature-plan.md --project api
/jira-push API-003
/review
/pulse
```

---

## Jira-linked tasks

Local tracker IDs stay in the tracker format:
- `APP-001`
- `API-014`

Jira does not replace that ID.

When a task is created from Jira:
- the local task title becomes `{JIRA-KEY}: {Jira summary}`
- the local `id` still uses the tracker prefix
- the task can also store:
  - `jira_key`
  - `jira_url`

When a local task is pushed to Jira:
- the local title and description are used to create the Jira issue
- the returned Jira key and URL are written back to the task file

---

## How it's structured

```text
my-tasks/
├── dashboard.md
├── projects/
├── tasks/
├── daily/
├── weekly/
├── templates/
├── kanban/
├── analytics/
├── archive/
├── .claude/commands/
├── AGENTS.md
└── CLAUDE.md
```

Codex registration model:
- prompts stay in `.claude/commands/`
- `setup-codex.sh` and `refresh-codex-skills.sh` create or update `~/.agents/skills/<name>/SKILL.md`
- each generated `SKILL.md` is copied from `.claude/commands/<name>.md`
- generation rewrites `CLAUDE.md` to `AGENTS.md`
- generation rewrites `/command` to `/skills:command`

### Task file format

Each task is a standalone markdown file:

```yaml
---
id: APP-003
title: "API-42: Add rate limiting"
status: todo
project: api
priority: high
due: 2025-03-01
tags: [backend, security]
created: 2025-01-20
completed:
blocked_by:
effort: 2h
actual:
jira_key: API-42
jira_url: https://your-company.atlassian.net/browse/API-42
---
```

### Dashboard

`dashboard.md` renders live Dataview queries:
- active tasks by project
- overdue items
- due this week
- high-priority backlog
- recently completed tasks
- blocked items
- project health overview
- weekly velocity

---

## Adding projects manually

You can use the scripts or manage the files manually:

1. Create `projects/<name>.md` with frontmatter like `id_prefix`, `next_id`, and `repo`
2. Create `tasks/<name>/`
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

---

## Plugin configuration

**Templater**
- Template folder: `templates/`
- Enable "Trigger on new file creation"
- Enable "System commands"

**Periodic Notes**
- Daily: folder `daily/{{date:YYYY}}/{{date:MM}}`, format `{{date:YYYY-MM-DD}}`, template `templates/daily-template.md`
- Weekly: folder `weekly/{{date:YYYY}}`, format `{{date:YYYY-[W]WW}}`, template `templates/weekly-template.md`

**Homepage** (optional)
- `dashboard`

---

## Design principles

- **Local-first**: plain markdown on your disk, works offline
- **Git-native**: every change is tracked, diffable, mergeable
- **No lock-in**: works without Claude Code, works without Obsidian
- **Convention over configuration**: file names, frontmatter schema, and folder structure are the database

## Requirements

- [Obsidian](https://obsidian.md)
- Claude Code or OpenAI Codex
- Git

## License

MIT
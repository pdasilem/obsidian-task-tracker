# Task Tracker Vault

vault_path: /absolute/path/to/this/vault

Obsidian vault for task tracking across multiple projects.
Used by OpenAI Codex through repo instructions and shell scripts.

## Directory Structure

- `tasks/<project>/` -- task files with YAML frontmatter
- `projects/` -- project index files with metadata and Dataview queries
- `daily/<YYYY>/<MM>/` -- daily notes
- `weekly/<YYYY>/` -- weekly notes
- `templates/` -- Templater templates
- `kanban/` -- Kanban board files
- `analytics/` -- burndown logs
- `archive/` -- completed or removed project data
- `dashboard.md` -- main dashboard

## Task File Conventions

- Path: `tasks/{project}/{kebab-case-slug}.md`
- Required frontmatter: id, title, status, project, priority, created
- Status: todo | in-progress | done | blocked | cancelled
- Priority: high | medium | low
- Dates: YYYY-MM-DD
- Effort: 30m, 1h, 2h, 4h, 1d, 2d, 1w
- IDs: {PREFIX}-{NNN} (e.g., APP-001, WEB-012)

## Project Repos

| Project | Repo Path | ID Prefix |
|---------|-----------|-----------|

## Codex Workflow

1. Use `./setup-codex.sh` to initialize a Codex-ready vault.
2. Use `./add-project.sh` to add a project for both Claude Code and Codex.
3. Use `./remove-project.sh` to remove a project from both environments.
4. Keep task and project data in the shared markdown structure under this vault.

## Git Log Commands

Always use full absolute paths from project `repo` fields.
Use `--oneline` and `--since`/`--until` for date filtering.

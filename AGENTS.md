# Task Tracker Vault

vault_path: /absolute/path/to/this/vault

Obsidian vault for task tracking across multiple projects.
Uses YAML frontmatter in markdown files, Dataview queries, and Templater templates.

## Directory Structure

- `tasks/<project>/` -- task files with YAML frontmatter
- `projects/` -- project index files with metadata and Dataview queries
- `daily/<YYYY>/<MM>/` -- daily notes
- `weekly/<YYYY>/` -- weekly notes
- `templates/` -- Templater templates (do NOT modify during agent commands)
- `kanban/` -- Kanban board files
- `analytics/` -- burndown logs
- `archive/` -- completed/old tasks
- `dashboard.md` -- main dashboard

## Task File Conventions

- Path: `tasks/{project}/{kebab-case-slug}.md`
- Required frontmatter: id, title, status, project, priority, created
- Optional frontmatter: jira_key, jira_url
- Status: todo | in-progress | done | blocked | cancelled
- Priority: high | medium | low
- Dates: YYYY-MM-DD
- Effort: 30m, 1h, 2h, 4h, 1d, 2d, 1w
- IDs: {PREFIX}-{NNN} (e.g., APP-001, WEB-012)

## Project Repos

| Project | Repo Path | ID Prefix |
|---------|-----------|-----------|

## When Creating Tasks

1. Read `projects/<project>.md` to get `id_prefix` and `next_id`
2. Generate ID: `{id_prefix}-{next_id zero-padded to 3}`
3. Create `tasks/<project>/<slug>.md`
4. If task source is Jira, store `jira_key` and `jira_url`
5. Increment `next_id` in the project file

## When Completing Tasks

1. Set `status: done` and `completed:` to today's date
2. Add log entry
3. Check if any other tasks have this one in `blocked_by`

## Git Log Commands

Always use full absolute paths from project `repo` fields.
Use `--oneline` and `--since`/`--until` for date filtering.

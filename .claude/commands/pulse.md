Generate a cross-project pulse report.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Steps

1. Read all project files in `projects/*.md` to get project names and repo paths.
2. Read all task files in `tasks/*/`.
3. For each project, compute:
   - Total active tasks (status != done and != cancelled)
   - In progress count
   - Blocked count
   - Overdue count (due < today, not done)
   - Completed this week (completed >= Monday of current week)
4. Run `git log --oneline --since="{monday}"` for each project repo to get this week's git activity.
5. Generate a health assessment:
   - HEALTHY: 0 overdue, 0 blocked, at least 1 completion this week
   - NEEDS ATTENTION: 1-2 overdue OR blocked items
   - AT RISK: 3+ overdue OR no completions in 2+ weeks

6. Output a clean summary:

```
## Project Pulse — {date}

| Project | Active | In Progress | Blocked | Overdue | Done (week) | Health |
|---------|--------|-------------|---------|---------|-------------|--------|
| ...     | ...    | ...         | ...     | ...     | ...         | ...    |

### Git Activity This Week
**{Project}**: N commits — [latest commit message]
...

### Needs Attention
- [list any overdue or blocked items]

### Momentum
- Most active: [project with most completions]
- Stale: [projects with no activity]
```

If the argument is "update", also update `dashboard.md` with fresh data.

$ARGUMENTS

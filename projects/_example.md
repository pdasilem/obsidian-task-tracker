---
project: _example
full_name: Example Project
repo:
remote:
status: active
started: 2025-01-01
color: "#4A90D9"
id_prefix: EX
next_id: 2
---

# Example Project

This is a sample project file showing the expected format. You can delete this after running `setup.sh` to create your own projects.

**Key fields:**
- `project`: folder name (lowercase, used in paths like `tasks/myapp/`)
- `full_name`: display name for reports
- `repo`: absolute path to the project's git repo (optional — enables git activity tracking)
- `id_prefix`: short uppercase prefix for task IDs (e.g., APP, WEB, API)
- `next_id`: auto-incremented by the `/task` command

## Active Tasks

```dataview
TABLE status, priority, due, effort
FROM "tasks/_example"
WHERE status != "done" AND status != "cancelled"
SORT choice(priority, "high", 1, "medium", 2, "low", 3) ASC, due ASC
```

## Recently Completed

```dataview
TABLE completed, actual
FROM "tasks/_example"
WHERE status = "done"
SORT completed DESC
LIMIT 10
```

## Velocity (Last 4 Weeks)

```dataview
TABLE length(rows) as "Tasks Completed"
FROM "tasks/_example"
WHERE status = "done" AND completed >= date(today) - dur(28d)
GROUP BY dateformat(completed, "yyyy-'W'WW") as Week
SORT Week DESC
```

---
type: dashboard
---

# Task Tracker Dashboard

## Active Tasks by Project

```dataview
TABLE WITHOUT ID
  project as "Project",
  length(filter(rows, (r) => r.status = "todo")) as "Todo",
  length(filter(rows, (r) => r.status = "in-progress")) as "In Progress",
  length(filter(rows, (r) => r.status = "blocked")) as "Blocked",
  length(filter(rows, (r) => r.status = "done")) as "Done",
  length(rows) as "Total"
FROM "tasks"
WHERE status != "cancelled"
GROUP BY project
SORT project ASC
```

## Overdue

```dataview
TABLE project, priority, due, status, effort
FROM "tasks"
WHERE due < date(today) AND status != "done" AND status != "cancelled"
SORT due ASC
```

## Due This Week

```dataview
TABLE project, priority, due, status
FROM "tasks"
WHERE due >= date(today) AND due <= date(today) + dur(7d) AND status != "done" AND status != "cancelled"
SORT due ASC
```

## High Priority

```dataview
TABLE project, status, due, effort
FROM "tasks"
WHERE priority = "high" AND status != "done" AND status != "cancelled"
SORT due ASC
```

## Recently Completed (Last 7 Days)

```dataview
TABLE project, completed, actual
FROM "tasks"
WHERE status = "done" AND completed >= date(today) - dur(7d)
SORT completed DESC
```

## Blocked Items

```dataview
TABLE project, blocked_by, due
FROM "tasks"
WHERE status = "blocked"
SORT due ASC
```

## Project Health

```dataview
TABLE WITHOUT ID
  project as "Project",
  length(filter(rows, (r) => r.due < date(today) AND r.status != "done" AND r.status != "cancelled")) as "Overdue",
  length(filter(rows, (r) => r.status = "blocked")) as "Blocked",
  length(filter(rows, (r) => r.status = "in-progress")) as "Active",
  length(filter(rows, (r) => r.status = "done" AND r.completed >= date(today) - dur(7d))) as "Done (7d)"
FROM "tasks"
GROUP BY project
SORT project ASC
```

## Weekly Velocity (Last 8 Weeks)

```dataview
TABLE length(rows) as "Tasks Completed"
FROM "tasks"
WHERE status = "done" AND completed >= date(today) - dur(56d)
GROUP BY dateformat(completed, "yyyy-'W'WW") as Week
SORT Week DESC
```

---

[[projects/|Projects]]

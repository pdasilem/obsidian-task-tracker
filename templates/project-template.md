---
project: <% tp.file.title %>
full_name:
repo:
remote:
status: active
started: <% tp.date.now("YYYY-MM-DD") %>
color:
id_prefix:
next_id: 1
---

# <% tp.file.title %>

## Active Tasks

```dataview
TABLE status, priority, due, effort
FROM "tasks/<% tp.file.title %>"
WHERE status != "done" AND status != "cancelled"
SORT choice(priority, "high", 1, "medium", 2, "low", 3) ASC, due ASC
```

## Recently Completed

```dataview
TABLE completed, actual
FROM "tasks/<% tp.file.title %>"
WHERE status = "done"
SORT completed DESC
LIMIT 10
```

## Velocity (Last 4 Weeks)

```dataview
TABLE length(rows) as "Tasks Completed"
FROM "tasks/<% tp.file.title %>"
WHERE status = "done" AND completed >= date(today) - dur(28d)
GROUP BY dateformat(completed, "yyyy-'W'WW") as Week
SORT Week DESC
```

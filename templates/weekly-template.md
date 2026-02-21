---
type: weekly
week: <% tp.date.now("YYYY-[W]WW") %>
---

# Week <% tp.date.now("[W]WW, YYYY") %>

## Tasks Completed This Week

```dataview
TABLE project, completed, actual
FROM "tasks"
WHERE status = "done" AND completed >= date(today) - dur(6d)
SORT completed ASC
```

## Velocity by Project

```dataview
TABLE length(rows) as "Completed"
FROM "tasks"
WHERE status = "done" AND completed >= date(today) - dur(6d)
GROUP BY project
```

## Tasks Created This Week

```dataview
TABLE project, status, priority
FROM "tasks"
WHERE created >= date(today) - dur(6d)
SORT project ASC
```

## Blocked Items

```dataview
TABLE project, blocked_by, due
FROM "tasks"
WHERE status = "blocked"
SORT due ASC
```

## Retrospective

### What went well



### What could be better



### Key decisions



## Next Week Planning

### Priorities

1.
2.
3.

### Carry-over

```dataview
TABLE project, priority, due
FROM "tasks"
WHERE status = "in-progress"
SORT priority ASC
```

---

[[<% tp.date.now("YYYY-[W]WW", -7) %>|Last Week]] | [[<% tp.date.now("YYYY-[W]WW", 7) %>|Next Week]]

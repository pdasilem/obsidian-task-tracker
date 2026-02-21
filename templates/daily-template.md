---
type: daily
date: <% tp.date.now("YYYY-MM-DD") %>
weekday: <% tp.date.now("dddd") %>
week: <% tp.date.now("YYYY-[W]WW") %>
energy:
tasks_completed: 0
tasks_created: 0
---

# <% tp.date.now("dddd, MMMM D, YYYY") %>

## Morning Planning

### Top 3 Priorities

1.
2.
3.

### Due Today

```dataview
TABLE project, priority, effort
FROM "tasks"
WHERE due = date("<% tp.date.now("YYYY-MM-DD") %>") AND status != "done" AND status != "cancelled"
SORT priority ASC
```

### Overdue

```dataview
TABLE project, priority, due, effort
FROM "tasks"
WHERE due < date("<% tp.date.now("YYYY-MM-DD") %>") AND status != "done" AND status != "cancelled"
SORT due ASC
```

### In Progress

```dataview
TABLE project, priority, due
FROM "tasks"
WHERE status = "in-progress"
SORT priority ASC
```

## Time Blocks

| Time | Block | Task/Notes |
|------|-------|------------|
| 09:00-10:30 | Deep Work | |
| 10:30-11:00 | Break | |
| 11:00-12:30 | Deep Work | |
| 12:30-13:30 | Lunch | |
| 13:30-14:00 | Comms | |
| 14:00-16:00 | Deep Work | |
| 16:00-16:30 | Break | |
| 16:30-18:00 | Wrap-up | |

## Git Activity

<%*
// Reads project files to get repo paths dynamically.
// Requires Templater system commands to be enabled.
const fs = require("fs");
const vaultPath = app.vault.adapter.basePath;
const projectDir = vaultPath + "/projects";
const files = fs.readdirSync(projectDir).filter(f => f.endsWith(".md") && !f.startsWith("_"));
const today = tp.date.now("YYYY-MM-DD");
const tomorrow = tp.date.now("YYYY-MM-DD", 1);
for (const file of files) {
  const content = fs.readFileSync(projectDir + "/" + file, "utf8");
  const nameMatch = content.match(/full_name:\s*(.+)/);
  const repoMatch = content.match(/repo:\s*(.+)/);
  const name = nameMatch ? nameMatch[1].trim() : file.replace(".md", "");
  const repo = repoMatch ? repoMatch[1].trim() : "";
  if (!repo) continue;
  tR += `### ${name}\n\`\`\`\n`;
  try {
    const log = await tp.system.command_output(`cd "${repo}" && git log --oneline --since="${today}" --until="${tomorrow}" 2>/dev/null || echo "No commits today"`);
    tR += log;
  } catch(e) {
    tR += "Could not fetch git log";
  }
  tR += `\n\`\`\`\n\n`;
}
if (files.every(f => {
  const content = fs.readFileSync(projectDir + "/" + f, "utf8");
  const repoMatch = content.match(/repo:\s*(.+)/);
  return !repoMatch || !repoMatch[1].trim();
})) {
  tR += "_No project repos configured yet. Add `repo:` paths in your project files._\n";
}
%>

## End of Day Review

### Completed Today

```dataview
LIST
FROM "tasks"
WHERE status = "done" AND completed = date("<% tp.date.now("YYYY-MM-DD") %>")
```

### Summary

- Tasks completed:
- Tasks created:
- Blockers:
- Key wins:
- Tomorrow's focus:

---

[[<% tp.date.now("YYYY-MM-DD", -1) %>|Yesterday]] | [[<% tp.date.now("YYYY-MM-DD", 1) %>|Tomorrow]] | [[<% tp.date.now("YYYY-[W]WW") %>|This Week]]

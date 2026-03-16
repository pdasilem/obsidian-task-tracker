---
name: review
description: Perform an end-of-day review.
---

Perform an end-of-day review.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Steps

1. Determine today's date.
2. Read today's daily note at `daily/{YYYY}/{MM}/{YYYY-MM-DD}.md`. If it doesn't exist, create it first (follow /today logic).
3. Scan all task files in `tasks/*/`:
   - Count tasks with `completed` = today (completed today)
   - Count tasks with `created` = today (created today)
   - List all tasks with `status` = "blocked"
   - List all tasks with `status` = "in-progress"
4. Update today's daily note:
   - Fill in the "End of Day Review > Summary" section with counts
   - Update frontmatter `tasks_completed` and `tasks_created`
5. Run `git log --oneline --since="{today}"` for each project repo (read `repo` field from each `projects/*.md` file) and update git activity sections.
6. Append a row to `analytics/burndown-log.md` with today's counts:
   - Date | Open (todo + in-progress) | Done (total ever) | Blocked | Created today
7. Print a terminal summary:
   - Tasks completed today (list with project)
   - Tasks still in progress
   - Blockers
   - Suggested focus for tomorrow (highest priority due items)

If the argument is "week", also generate/update this week's weekly note.

$ARGUMENTS

Generate or update today's daily note.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Steps

1. Determine today's date (YYYY-MM-DD).
2. Check if `daily/{YYYY}/{MM}/{YYYY-MM-DD}.md` exists.
3. If it does NOT exist, create it with this structure:
   - YAML frontmatter: type, date, weekday, week, energy (empty), tasks_completed (0), tasks_created (0)
   - Morning Planning section with "Top 3 Priorities" (empty)
   - "Due Today" section: read all files in `tasks/*/` and list those where `due` matches today and `status` is not done/cancelled
   - "Overdue" section: tasks where `due` < today and status is not done/cancelled
   - "In Progress" section: tasks where `status` = "in-progress"
   - Time Blocks table (empty schedule)
   - Git Activity: run `git log --oneline --since="{today}" --until="{tomorrow}"` for each project repo (read `repo` field from each `projects/*.md` file that has one)
   - End of Day Review section (empty)
   - Navigation links to yesterday, tomorrow, this week

4. If it DOES exist, read it and update:
   - Refresh the git activity sections with current data
   - Report any changes to due/overdue tasks since the note was created

5. Print a summary to terminal:
   - Tasks due today (count and list)
   - Overdue tasks (count and list)
   - Tasks in progress (count)
   - Suggest top priorities based on: overdue first, then due today, then high priority

$ARGUMENTS

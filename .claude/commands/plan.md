---
name: plan
description: Plan upcoming work.
---

Plan upcoming work.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Usage

- `/plan` or `/plan tomorrow` — plan for tomorrow
- `/plan week` — plan for next week

## Tomorrow Planning

1. Read all task files in `tasks/*/`.
2. Collect:
   - Tasks due tomorrow
   - Overdue tasks (due < today, not done)
   - High-priority tasks without due dates
   - Currently in-progress tasks
3. Suggest a top-3 priority list: overdue first, then due tomorrow, then highest priority.
4. Check if tomorrow's daily note exists (`daily/{YYYY}/{MM}/{YYYY-MM-DD}.md`).
   - If not, create it with the priorities pre-filled in "Top 3 Priorities"
   - If yes, update the priorities section
5. Print the plan to terminal.

## Week Planning

1. Read all task files.
2. Collect:
   - All tasks due in the coming week (Monday to Sunday)
   - Overdue backlog
   - Blocked items needing resolution
3. For each project, suggest 2-3 key tasks to focus on.
4. Create or update the weekly note for the coming week at `weekly/{YYYY}/{YYYY-WNN}.md`.
5. Suggest a day-by-day breakdown:
   - Spread tasks across days based on effort estimates
   - Group by project where possible for focus blocks
   - Leave buffer time (don't schedule >6h of tasks per day)
6. Print the full week plan to terminal.

$ARGUMENTS

Mark a task as completed.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Usage

`/done <task-id or search-term> [--actual <duration>]`

Examples:
- `/done APP-001`
- `/done APP-001 --actual 3h`
- `/done fix login` (will search for matching task)

## Steps

1. Parse the argument:
   - If it looks like an ID (e.g., APP-001, WEB-012): search all `tasks/*/` files for a matching `id` in frontmatter
   - If it's a file path: use it directly
   - Otherwise: search task titles for the closest match. If ambiguous, list matches and ask which one.

2. Read the task file.

3. Update the YAML frontmatter:
   - Set `status: done`
   - Set `completed: {today YYYY-MM-DD}`
   - If `--actual` provided, set `actual: {value}`

4. Add a log entry: `- {today}: Completed`

5. Check all other task files: if any have this task's filename or ID in their `blocked_by` field, report that those tasks may now be unblocked.

6. Print confirmation:
   - Task title, project, ID
   - Completion date
   - If `effort` was set, show estimated vs actual
   - Any newly unblocked tasks

$ARGUMENTS

Import tasks from an external list or document.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Usage

- `/import <file-path> --project <project>` — import from a file
- `/import` — then paste a list interactively

Examples:
- `/import ~/notes/feature-list.md --project myapp`
- `/import tasks.csv --project backend --priority medium`

## Steps

1. Parse the source:
   - If a file path is provided, read the file
   - If no path, ask the user to paste a list of tasks
2. Read the project file `projects/<project>.md` to get `id_prefix` and `next_id`.
3. Parse the input into individual tasks. Handle these formats:
   - Markdown lists (`- [ ] task` or `- task`)
   - Numbered lists (`1. task`)
   - CSV with headers (title, priority, due, effort, tags)
   - Plain text (one task per line)
4. For each task found:
   - Generate the next task ID: `{id_prefix}-{next_id zero-padded to 3}`
   - Generate the filename slug from the title
   - Create the task file at `tasks/<project>/<slug>.md` with default frontmatter
   - Increment `next_id`
5. Update `next_id` in the project file's frontmatter (once, with the final value).
6. Print a summary:
   - Number of tasks imported
   - List of task IDs and titles
   - Any lines that couldn't be parsed (ask about them)

$ARGUMENTS

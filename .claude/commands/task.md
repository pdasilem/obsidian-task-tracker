Create a new task file.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Usage

`/task <title> --project <project> --priority <high|medium|low> [--due YYYY-MM-DD] [--effort <duration>] [--tags tag1,tag2]`

Examples:
- `/task Fix login bug --project myapp --priority high --due 2025-02-25 --effort 2h --tags bug,auth`
- `/task Add user onboarding --project webapp --priority medium`
- `/task Research vector DB options --project backend --priority low --effort 4h`

## Steps

1. Parse the arguments. If `--project` is missing, ask which project.
   If `--priority` is missing, default to `medium`.
2. Read the project file `projects/<project>.md` to get `id_prefix` and `next_id`.
3. Generate the task ID: `{id_prefix}-{next_id zero-padded to 3 digits}` (e.g., APP-001).
4. Generate the filename slug: lowercase the title, replace spaces with hyphens, remove special chars, max 50 chars.
5. Create the task file at `tasks/<project>/<slug>.md` with:

```yaml
---
id: {generated ID}
title: {title from args}
status: todo
project: {project}
priority: {priority}
due: {due if provided}
tags: [{tags if provided}]
created: {today YYYY-MM-DD}
completed:
blocked_by:
effort: {effort if provided}
actual:
---

## Description

{title}

## Acceptance Criteria

- [ ]

## Notes



## Log

- {today}: Created
```

6. Increment `next_id` in the project file's frontmatter.
7. Print confirmation: task ID, file path, project, priority, due date.

$ARGUMENTS

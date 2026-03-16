---
name: task
description: Create a new task file.
---

Create a new task file.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Usage

`/task <title-or-jira-url> --project <project> --priority <high|medium|low> [--due YYYY-MM-DD] [--effort <duration>] [--tags tag1,tag2]`

Examples:
- `/task Fix login bug --project myapp --priority high --due 2025-02-25 --effort 2h --tags bug,auth`
- `/task https://your-company.atlassian.net/browse/APP-42 --project myapp --priority high`
- `/task Add user onboarding --project webapp --priority medium`
- `/task Research vector DB options --project backend --priority low --effort 4h`

## Steps

1. Parse the arguments. If `--project` is missing, ask which project.
   If `--priority` is missing, default to `medium`.
2. Determine whether the first positional argument is a Jira issue URL.
   - If it is a normal title, continue with local task creation.
   - If it is a Jira URL, try to fetch the issue through the available MCP Jira tool/server.
   - If no Jira MCP tool is available, stop and explain that Jira import requires the Jira MCP integration.
3. If Jira issue fetch succeeds:
   - Read the issue key, summary, description, and canonical issue URL.
   - Set the local task title to `{jira_key}: {summary}`.
   - Use the Jira description as the local task description body.
   - Store `jira_key` and `jira_url` in frontmatter.
   - Before creating a new task, search existing `tasks/*/` for the same `jira_key`; if found, stop and report the existing task instead of creating a duplicate.
4. Read the project file `projects/<project>.md` to get `id_prefix` and `next_id`.
5. Generate the task ID: `{id_prefix}-{next_id zero-padded to 3 digits}` (e.g., APP-001).
6. Generate the filename slug: lowercase the title, replace spaces with hyphens, remove special chars, max 50 chars.
7. Create the task file at `tasks/<project>/<slug>.md` with:

```markdown
---
id: {generated ID}
title: {title from args or Jira summary with jira key prefix}
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
jira_key: {jira key if imported from Jira}
jira_url: {jira issue URL if imported from Jira}
---

## Description

{title if local task, or Jira description if imported from Jira}

## Acceptance Criteria

- [ ]

## Notes



## Log

- {today}: Created
```

8. Increment `next_id` in the project file's frontmatter.
9. Print confirmation: task ID, file path, project, priority, due date, and Jira key/url if present.

$ARGUMENTS
---
name: jira-push
description: Create a Jira issue from an existing local task.
---

Create a Jira issue from an existing local task.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Usage

`/jira-push <task-id or search-term>`

Examples:
- `/jira-push APP-017`
- `/jira-push fix login`

## Steps

1. Parse the argument:
   - If it looks like a task ID (e.g., APP-001), search all `tasks/*/` files for a matching `id`.
   - Otherwise search task titles for the closest match. If ambiguous, list matches and ask which one.
2. Read the task file.
3. If `jira_key` is already populated, stop and report that the task is already linked to Jira, including `jira_key` and `jira_url` if present.
4. Extract the local task title and the `## Description` section.
5. Check whether a Jira MCP tool/server is available for issue creation.
   - If not available, stop and explain that Jira export requires the Jira MCP integration.
6. Create a Jira issue using:
   - Summary: local task `title`
   - Description: local task `## Description`
7. If Jira issue creation succeeds:
   - Read the returned Jira issue key and canonical issue URL.
   - Update the local task frontmatter:
     - `jira_key: {returned key}`
     - `jira_url: {returned url}`
   - Keep the local task `id` unchanged.
8. Print confirmation:
   - Local task ID and title
   - Jira key
   - Jira URL
9. If Jira creation succeeds but the local file update fails, print the Jira key and URL clearly so they can be written back manually.

$ARGUMENTS

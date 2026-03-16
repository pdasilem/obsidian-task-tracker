---
name: sync
description: Sync git activity across all project repos.
---

Sync git activity across all project repos.

Read the `vault_path` field from the CLAUDE.md in the task tracker root to determine the base path. All file paths below are relative to that vault_path.

## Usage

- `/sync` — fetch latest git activity for all projects
- `/sync <project>` — fetch for a specific project only

## Steps

1. Read all project files in `projects/*.md` to get project names and `repo` paths.
   Skip any projects without a `repo` field.
2. For each project repo:
   - Run `git -C "{repo}" fetch --quiet 2>/dev/null` to pull latest remote refs
   - Run `git -C "{repo}" log --oneline -10` to get recent commits
   - Run `git -C "{repo}" status --short` to check for uncommitted changes
   - Run `git -C "{repo}" branch --show-current` to get the current branch
3. If today's daily note exists, update the Git Activity section with fresh data.
4. Print a summary for each project:
   - Current branch
   - Last 5 commits (oneline)
   - Uncommitted changes (if any)
   - Ahead/behind remote (if tracking)

$ARGUMENTS

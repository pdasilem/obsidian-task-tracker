#!/usr/bin/env bash

tracker_replace_vault_path() {
  local file_path="$1"
  local vault_path="$2"
  local tmp_file

  tmp_file="$(tracker_tmp_file "$file_path")"
  awk -v vault_path="$vault_path" '
    BEGIN { updated = 0 }
    /^vault_path:/ {
      print "vault_path: " vault_path
      updated = 1
      next
    }
    { print }
    END {
      if (!updated) {
        print "vault_path: " vault_path
      }
    }
  ' "$file_path" > "$tmp_file"
  mv "$tmp_file" "$file_path"
}

tracker_replace_project_table() {
  local file_path="$1"
  local rows="$2"
  local tmp_file

  tmp_file="$(tracker_tmp_file "$file_path")"
  awk -v rows="$rows" '
    BEGIN {
      in_table = 0
    }
    /^\| Project \| Repo Path \| ID Prefix \|$/ {
      print
      getline
      print
      if (rows != "") {
        print rows
      }
      in_table = 1
      next
    }
    in_table == 1 {
      if ($0 == "") {
        print ""
        in_table = 0
      }
      next
    }
    { print }
  ' "$file_path" > "$tmp_file"
  mv "$tmp_file" "$file_path"
}

tracker_sync_claude_config() {
  local rows
  local claude_file="$TRACKER_ROOT/CLAUDE.md"

  [[ -f "$claude_file" ]] || return 0
  rows="$(tracker_collect_project_rows)"
  tracker_replace_vault_path "$claude_file" "$TRACKER_ROOT"
  tracker_replace_project_table "$claude_file" "$rows"
}

tracker_render_agents_config() {
  local rows="$1"

  cat <<EOF
# Task Tracker Vault

vault_path: $TRACKER_ROOT

Obsidian vault for task tracking across multiple projects.
Uses YAML frontmatter in markdown files, Dataview queries, and Templater templates.

## Directory Structure

- \`tasks/<project>/\` -- task files with YAML frontmatter
- \`projects/\` -- project index files with metadata and Dataview queries
- \`daily/<YYYY>/<MM>/\` -- daily notes
- \`weekly/<YYYY>/\` -- weekly notes
- \`templates/\` -- Templater templates (do NOT modify during agent commands)
- \`kanban/\` -- Kanban board files
- \`analytics/\` -- burndown logs
- \`archive/\` -- completed/old tasks
- \`dashboard.md\` -- main dashboard

## Task File Conventions

- Path: \`tasks/{project}/{kebab-case-slug}.md\`
- Required frontmatter: id, title, status, project, priority, created
- Optional frontmatter: jira_key, jira_url
- Status: todo | in-progress | done | blocked | cancelled
- Priority: high | medium | low
- Dates: YYYY-MM-DD
- Effort: 30m, 1h, 2h, 4h, 1d, 2d, 1w
- IDs: {PREFIX}-{NNN} (e.g., APP-001, WEB-012)

## Project Repos

| Project | Repo Path | ID Prefix |
|---------|-----------|-----------|
${rows}

## When Creating Tasks

1. Read \`projects/<project>.md\` to get \`id_prefix\` and \`next_id\`
2. Generate ID: \`{id_prefix}-{next_id zero-padded to 3}\`
3. Create \`tasks/<project>/<slug>.md\`
4. If task source is Jira, store \`jira_key\` and \`jira_url\`
5. Increment \`next_id\` in the project file

## When Completing Tasks

1. Set \`status: done\` and \`completed:\` to today's date
2. Add log entry
3. Check if any other tasks have this one in \`blocked_by\`

## Git Log Commands

Always use full absolute paths from project \`repo\` fields.
Use \`--oneline\` and \`--since\`/\`--until\` for date filtering.
EOF
}

tracker_sync_agents_config() {
  local agents_file="$TRACKER_ROOT/AGENTS.md"
  local rows

  rows="$(tracker_collect_project_rows)"
  tracker_render_agents_config "$rows" | tracker_write_text "$agents_file"
}

tracker_sync_all_configs() {
  tracker_sync_claude_config
  tracker_sync_agents_config
}

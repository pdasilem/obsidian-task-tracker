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
Used by OpenAI Codex through repo instructions and shell scripts.

## Directory Structure

- \`tasks/<project>/\` -- task files with YAML frontmatter
- \`projects/\` -- project index files with metadata and Dataview queries
- \`daily/<YYYY>/<MM>/\` -- daily notes
- \`weekly/<YYYY>/\` -- weekly notes
- \`templates/\` -- Templater templates
- \`kanban/\` -- Kanban board files
- \`analytics/\` -- burndown logs
- \`archive/\` -- completed or removed project data
- \`dashboard.md\` -- main dashboard

## Task File Conventions

- Path: \`tasks/{project}/{kebab-case-slug}.md\`
- Required frontmatter: id, title, status, project, priority, created
- Status: todo | in-progress | done | blocked | cancelled
- Priority: high | medium | low
- Dates: YYYY-MM-DD
- Effort: 30m, 1h, 2h, 4h, 1d, 2d, 1w
- IDs: {PREFIX}-{NNN} (e.g., APP-001, WEB-012)

## Project Repos

| Project | Repo Path | ID Prefix |
|---------|-----------|-----------|
${rows}

## Codex Workflow

1. Use \`./setup-codex.sh\` to initialize a Codex-ready vault.
2. Use \`./add-project.sh\` to add a project for both Claude Code and Codex.
3. Use \`./remove-project.sh\` to remove a project from both environments.
4. Keep task and project data in the shared markdown structure under this vault.

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

#!/usr/bin/env bash

tracker_project_file() {
  printf '%s\n' "$TRACKER_ROOT/projects/$1.md"
}

tracker_task_dir() {
  printf '%s\n' "$TRACKER_ROOT/tasks/$1"
}

tracker_archive_dir() {
  printf '%s\n' "$TRACKER_ROOT/archive/$1"
}

tracker_project_name_valid() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

tracker_prefix_valid() {
  [[ "$1" =~ ^[A-Z][A-Z0-9]{1,7}$ ]]
}

tracker_project_file_field() {
  local file_path="$1"
  local field_name="$2"
  local value

  value="$(sed -n "s/^${field_name}:[[:space:]]*//p" "$file_path" | head -n 1)"
  printf '%s\n' "$value"
}

tracker_list_project_files() {
  find "$TRACKER_ROOT/projects" -maxdepth 1 -type f -name '*.md' ! -name '_*' | sort
}

tracker_project_exists() {
  [[ -f "$(tracker_project_file "$1")" ]]
}

tracker_prefix_in_use() {
  local prefix="$1"
  local exclude_project="${2:-}"
  local file
  local file_project
  local file_prefix

  while IFS= read -r file; do
    file_project="$(tracker_project_file_field "$file" "project")"
    file_prefix="$(tracker_project_file_field "$file" "id_prefix")"
    [[ -n "$exclude_project" && "$file_project" == "$exclude_project" ]] && continue
    [[ "$file_prefix" == "$prefix" ]] && return 0
  done < <(tracker_list_project_files)

  return 1
}

tracker_validate_project_spec() {
  local name="$1"
  local full_name="$2"
  local prefix="$3"
  local repo_path="$4"
  local exclude_project="${5:-}"

  tracker_project_name_valid "$name" || return 1
  [[ -n "$full_name" ]] || return 1
  tracker_prefix_valid "$prefix" || return 1
  tracker_require_absolute_dir "$repo_path" || return 1

  if [[ -z "$exclude_project" || "$exclude_project" != "$name" ]]; then
    ! tracker_project_exists "$name" || return 1
  fi

  ! tracker_prefix_in_use "$prefix" "$exclude_project" || return 1
  return 0
}

tracker_render_project_file() {
  local name="$1"
  local full_name="$2"
  local prefix="$3"
  local repo_path="$4"

  cat <<EOF
---
project: $name
full_name: $full_name
repo: $repo_path
remote:
status: active
started: $(tracker_today)
color:
id_prefix: $prefix
next_id: 1
---

# $full_name

## Active Tasks

\`\`\`dataview
TABLE status, priority, due, effort
FROM "tasks/$name"
WHERE status != "done" AND status != "cancelled"
SORT choice(priority, "high", 1, "medium", 2, "low", 3) ASC, due ASC
\`\`\`

## Recently Completed

\`\`\`dataview
TABLE completed, actual
FROM "tasks/$name"
WHERE status = "done"
SORT completed DESC
LIMIT 10
\`\`\`

## Velocity (Last 4 Weeks)

\`\`\`dataview
TABLE length(rows) as "Tasks Completed"
FROM "tasks/$name"
WHERE status = "done" AND completed >= date(today) - dur(28d)
GROUP BY dateformat(completed, "yyyy-'W'WW") as Week
SORT Week DESC
\`\`\`
EOF
}

tracker_create_project_assets() {
  local name="$1"
  local full_name="$2"
  local prefix="$3"
  local repo_path="$4"

  tracker_ensure_base_dirs
  tracker_ensure_gitkeep "$(tracker_task_dir "$name")"
  tracker_ensure_gitkeep "$(tracker_archive_dir "$name")"
  tracker_render_project_file "$name" "$full_name" "$prefix" "$repo_path" | tracker_write_text "$(tracker_project_file "$name")"
}

tracker_collect_project_rows() {
  local file
  local name
  local repo_path
  local prefix

  while IFS= read -r file; do
    name="$(tracker_project_file_field "$file" "project")"
    repo_path="$(tracker_project_file_field "$file" "repo")"
    prefix="$(tracker_project_file_field "$file" "id_prefix")"
    printf '| %s | %s | %s |\n' "$name" "$repo_path" "$prefix"
  done < <(tracker_list_project_files)
}

#!/usr/bin/env bash
set -euo pipefail

TRACKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TRACKER_ROOT/scripts/lib/common.sh"
source "$TRACKER_ROOT/scripts/lib/project_registry.sh"
source "$TRACKER_ROOT/scripts/lib/config_render.sh"

suggest_prefix() {
  printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]' | cut -c1-3
}

tracker_info "============================================"
tracker_info "  Obsidian Task Tracker — Setup"
tracker_info "============================================"
tracker_info ""
tracker_info "Vault path: $TRACKER_ROOT"
tracker_info ""

tracker_info "Enter your project names (one per line, lowercase, no spaces)."
tracker_info "For each project you'll also set a display name, ID prefix, and optional repo path."
tracker_info "Press Enter on an empty line when done."
tracker_info "Input order for one project:"
tracker_info "  1. Project name"
tracker_info "  2. Display name"
tracker_info "  3. ID prefix"
tracker_info "  4. Git repo path"
tracker_info "Example stdin block for one project:"
tracker_info "  myapp"
tracker_info "  My App"
tracker_info "  APP"
tracker_info "  /home/you/work/myapp"
tracker_info ""

projects=()
declare -A seen_names=()
declare -A seen_prefixes=()

while true; do
  name="$(tracker_prompt "Project name (lowercase, no spaces; Enter to finish, e.g. myapp)")"
  [[ -z "$name" ]] && break

  full_name="$(tracker_prompt "  Display name (human-readable, e.g. My App)" "$name")"
  prefix="$(tracker_prompt "  ID prefix (uppercase short code, e.g. APP)" "$(suggest_prefix "$name")")"
  prefix="$(tracker_normalize_prefix "$prefix")"
  repo_path="$(tracker_prompt "  Git repo path (optional absolute path, e.g. /home/you/work/myapp)" )"

  tracker_project_name_valid "$name" || tracker_die "Invalid project name: $name" 2
  [[ -n "$full_name" ]] || tracker_die "Display name cannot be empty for project: $name" 2
  tracker_prefix_valid "$prefix" || tracker_die "Invalid project prefix: $prefix" 2
  tracker_require_absolute_dir "$repo_path" || tracker_die "Repo path must be an existing absolute directory: $repo_path" 2
  [[ -z "${seen_names[$name]:-}" ]] || tracker_die "Duplicate project in this setup run: $name" 2
  [[ -z "${seen_prefixes[$prefix]:-}" ]] || tracker_die "Duplicate prefix in this setup run: $prefix" 2
  [[ ! -f "$(tracker_project_file "$name")" ]] || tracker_die "Project already exists: $name" 2
  ! tracker_prefix_in_use "$prefix" || tracker_die "Project prefix already exists: $prefix" 2

  projects+=("$name|$full_name|$prefix|$repo_path")
  seen_names["$name"]=1
  seen_prefixes["$prefix"]=1
  tracker_info ""
done

if [[ ${#projects[@]} -eq 0 ]]; then
  tracker_info "No projects added. You can add them later by creating files in projects/ and tasks/."
  tracker_info ""
fi

tracked_paths=("$TRACKER_ROOT/CLAUDE.md")
tracked_backups=("$(tracker_backup_path "$TRACKER_ROOT/CLAUDE.md")")

for entry in "${projects[@]}"; do
  IFS='|' read -r name _ _ _ <<< "$entry"
  tracked_paths+=("$(tracker_project_file "$name")")
  tracked_backups+=("$(tracker_backup_path "$(tracker_project_file "$name")")")
  tracked_paths+=("$(tracker_task_dir "$name")")
  tracked_backups+=("$(tracker_backup_path "$(tracker_task_dir "$name")")")
  tracked_paths+=("$(tracker_archive_dir "$name")")
  tracked_backups+=("$(tracker_backup_path "$(tracker_archive_dir "$name")")")
done

rollback_changes() {
  local idx
  for ((idx=${#tracked_paths[@]}-1; idx>=0; idx--)); do
    tracker_restore_path "${tracked_paths[$idx]}" "${tracked_backups[$idx]}"
  done
}

cleanup_backups() {
  local backup_ref
  for backup_ref in "${tracked_backups[@]}"; do
    tracker_cleanup_backup "$backup_ref"
  done
}

tracker_ensure_base_dirs

for entry in "${projects[@]}"; do
  IFS='|' read -r name full_name prefix repo_path <<< "$entry"
  if ! tracker_create_project_assets "$name" "$full_name" "$prefix" "$repo_path"; then
    rollback_changes
    cleanup_backups
    tracker_die "Failed to create project assets for $name" 6
  fi
  tracker_info "Created project: $name ($prefix)"
done

if ! tracker_sync_claude_config; then
  rollback_changes
  cleanup_backups
  tracker_die "Failed to update CLAUDE.md" 5
fi

tracker_info ""
tracker_info "Updated vault_path in CLAUDE.md"
tracker_info ""
tracker_info "Updated project table in CLAUDE.md"

if [[ ! -d "$TRACKER_ROOT/.git" ]]; then
  tracker_info ""
  if tracker_confirm "Initialize git repository?" "Y"; then
    git init "$TRACKER_ROOT" >/dev/null
    tracker_info "Git repository initialized"
  fi
fi

cleanup_backups

tracker_info ""
tracker_info "============================================"
tracker_info "  Setup complete!"
tracker_info "============================================"
tracker_info ""
tracker_info "Next steps:"
tracker_info "  1. Open this folder as an Obsidian vault"
tracker_info "  2. Install community plugins: Dataview, Templater, Periodic Notes,"
tracker_info "     Calendar, Kanban, Tasks"
tracker_info "  3. Configure Templater: set template folder to 'templates/'"
tracker_info "  4. Configure Periodic Notes:"
tracker_info "     - Daily: format 'YYYY/MM/YYYY-MM-DD', folder 'daily/'"
tracker_info "     - Weekly: format 'YYYY/YYYY-[W]WW', folder 'weekly/'"
tracker_info "  5. Example project link: /home/you/work/myapp"
tracker_info "  6. Start tracking: claude /task \"My first task\" --project <name>"
tracker_info ""
tracker_info "You can safely delete projects/_example.md and tasks/_example/"
tracker_info "once you've created your own projects."

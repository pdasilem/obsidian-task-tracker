#!/usr/bin/env bash
set -euo pipefail

TRACKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TRACKER_ROOT/scripts/lib/common.sh"
source "$TRACKER_ROOT/scripts/lib/project_registry.sh"
source "$TRACKER_ROOT/scripts/lib/config_render.sh"

suggest_prefix() {
  printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]' | cut -c1-3
}

project_name=""
project_full_name=""
project_prefix=""
project_repo=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      project_name="${2:-}"
      shift 2
      ;;
    --display-name)
      project_full_name="${2:-}"
      shift 2
      ;;
    --prefix)
      project_prefix="${2:-}"
      shift 2
      ;;
    --repo)
      project_repo="${2:-}"
      shift 2
      ;;
    --yes)
      shift
      ;;
    *)
      tracker_die "Unknown argument: $1" 2
      ;;
  esac
done

if [[ -z "$project_name" ]]; then
  project_name="$(tracker_prompt "Project name")"
fi

[[ -n "$project_name" ]] || tracker_die "Project name is required" 2
project_full_name="${project_full_name:-$(tracker_prompt "Display name" "$project_name")}"
project_prefix="${project_prefix:-$(suggest_prefix "$project_name")}"
project_prefix="$(tracker_normalize_prefix "$project_prefix")"

if [[ -z "$project_repo" && -t 0 ]]; then
  project_repo="$(tracker_prompt "Git repo path (optional, Enter to skip)")"
fi

tracker_validate_project_spec "$project_name" "$project_full_name" "$project_prefix" "$project_repo" \
  || tracker_die "Invalid project input or duplicate project/prefix" 3

tracked_paths=(
  "$TRACKER_ROOT/CLAUDE.md"
  "$TRACKER_ROOT/AGENTS.md"
  "$(tracker_project_file "$project_name")"
  "$(tracker_task_dir "$project_name")"
  "$(tracker_archive_dir "$project_name")"
)
tracked_backups=()

for target in "${tracked_paths[@]}"; do
  tracked_backups+=("$(tracker_backup_path "$target")")
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

if ! tracker_create_project_assets "$project_name" "$project_full_name" "$project_prefix" "$project_repo"; then
  rollback_changes
  cleanup_backups
  tracker_die "Failed to create project assets" 6
fi

if ! tracker_sync_all_configs; then
  rollback_changes
  cleanup_backups
  tracker_die "Failed to update CLAUDE.md and AGENTS.md" 5
fi

cleanup_backups

tracker_info "Project created successfully:"
tracker_info "  Name: $project_name"
tracker_info "  Display name: $project_full_name"
tracker_info "  Prefix: $project_prefix"
tracker_info "  Project file: $(tracker_project_file "$project_name")"
tracker_info "  Task directory: $(tracker_task_dir "$project_name")"
tracker_info "  Archive directory: $(tracker_archive_dir "$project_name")"

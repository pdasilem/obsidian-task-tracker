#!/usr/bin/env bash
set -euo pipefail

TRACKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TRACKER_ROOT/scripts/lib/common.sh"
source "$TRACKER_ROOT/scripts/lib/project_registry.sh"
source "$TRACKER_ROOT/scripts/lib/config_render.sh"

project_name=""
delete_data=0
assume_yes=0
snapshot_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      project_name="${2:-}"
      shift 2
      ;;
    --delete-data)
      delete_data=1
      shift
      ;;
    --yes)
      assume_yes=1
      shift
      ;;
    *)
      tracker_die "Unknown argument: $1" 2
      ;;
  esac
done

[[ -n "$project_name" ]] || tracker_die "Project name is required" 2
tracker_project_exists "$project_name" || tracker_die "Project not found: $project_name" 3

if [[ "$assume_yes" -eq 0 ]]; then
  if ! tracker_confirm "Remove project '$project_name'?" "N"; then
    tracker_die "Project removal cancelled" 4
  fi
fi

project_file="$(tracker_project_file "$project_name")"
task_dir="$(tracker_task_dir "$project_name")"
archive_dir="$(tracker_archive_dir "$project_name")"

tracked_paths=(
  "$TRACKER_ROOT/CLAUDE.md"
  "$TRACKER_ROOT/AGENTS.md"
  "$project_file"
  "$task_dir"
  "$archive_dir"
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
  [[ -n "$snapshot_dir" ]] && rm -rf "$snapshot_dir"
}

cleanup_backups() {
  local backup_ref
  for backup_ref in "${tracked_backups[@]}"; do
    tracker_cleanup_backup "$backup_ref"
  done
}

if [[ "$delete_data" -eq 1 ]]; then
  rm -rf "$project_file" "$task_dir" "$archive_dir"
else
  snapshot_dir="$(tracker_removed_projects_dir)/${project_name}-$(tracker_now_stamp)"
  mkdir -p "$snapshot_dir"

  [[ -e "$project_file" ]] && mv "$project_file" "$snapshot_dir/project.md"
  [[ -e "$task_dir" ]] && mv "$task_dir" "$snapshot_dir/tasks"
  [[ -e "$archive_dir" ]] && mv "$archive_dir" "$snapshot_dir/archive"
fi

if ! tracker_sync_all_configs; then
  rollback_changes
  cleanup_backups
  tracker_die "Failed to update CLAUDE.md and AGENTS.md during removal" 5
fi

cleanup_backups

tracker_info "Project removed successfully: $project_name"
if [[ "$delete_data" -eq 1 ]]; then
  tracker_info "  Mode: delete-data"
else
  tracker_info "  Mode: archive-preserving"
  tracker_info "  Snapshot: $snapshot_dir"
fi

#!/usr/bin/env bash
set -euo pipefail

TRACKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TRACKER_ROOT/scripts/lib/common.sh"
source "$TRACKER_ROOT/scripts/lib/codex_skills.sh"
source "$TRACKER_ROOT/scripts/lib/project_registry.sh"
source "$TRACKER_ROOT/scripts/lib/config_render.sh"

suggest_prefix() {
  printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]' | cut -c1-3
}

project_name=""
project_full_name=""
project_prefix=""
project_repo=""
skip_git_init=0
assume_yes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
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
    --no-git-init)
      skip_git_init=1
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

tracker_info "============================================"
tracker_info "  Obsidian Task Tracker — Codex Setup"
tracker_info "============================================"
tracker_info ""
tracker_info "Vault path: $TRACKER_ROOT"
tracker_info ""
tracker_info "You can add projects interactively or with flags."
tracker_info "Interactive input order for one project:"
tracker_info "  1. Project name"
tracker_info "  2. Display name"
tracker_info "  3. ID prefix"
tracker_info "  4. Git repo path"
tracker_info "Example values:"
tracker_info "  myapp"
tracker_info "  My App"
tracker_info "  APP"
tracker_info "  /home/you/work/myapp"

projects=()

if [[ -n "$project_name" ]]; then
  if tracker_is_interactive; then
    project_full_name="${project_full_name:-$(tracker_prompt "Display name (human-readable, e.g. My App)" "$project_name")}"
    project_prefix="${project_prefix:-$(tracker_prompt "ID prefix (uppercase short code, e.g. APP)" "$(suggest_prefix "$project_name")")}"
    project_repo="${project_repo:-$(tracker_prompt "Git repo path (optional absolute path, e.g. /home/you/work/myapp)")}"
  else
    project_full_name="${project_full_name:-$project_name}"
    project_prefix="${project_prefix:-$(suggest_prefix "$project_name")}"
  fi
  project_prefix="$(tracker_normalize_prefix "$project_prefix")"
  projects+=("$project_name|$project_full_name|$project_prefix|$project_repo")
else
  tracker_info ""
  tracker_info "Enter your project names (one per line, lowercase, no spaces)."
  tracker_info "For each project you'll also set a display name, ID prefix, and optional repo path."
  tracker_info "Press Enter on an empty line when done."
  tracker_info "Input order for one project: name, display name, ID prefix, repo path."
  tracker_info "Example stdin block:"
  tracker_info "  myapp"
  tracker_info "  My App"
  tracker_info "  APP"
  tracker_info "  /home/you/work/myapp"
  tracker_info ""

  while true; do
    name="$(tracker_prompt "Project name (lowercase, no spaces; Enter to finish, e.g. myapp)")"
    [[ -z "$name" ]] && break

    full_name="$(tracker_prompt "  Display name (human-readable, e.g. My App)" "$name")"
    prefix="$(tracker_prompt "  ID prefix (uppercase short code, e.g. APP)" "$(suggest_prefix "$name")")"
    prefix="$(tracker_normalize_prefix "$prefix")"
    repo="$(tracker_prompt "  Git repo path (optional absolute path, e.g. /home/you/work/myapp)")"

    projects+=("$name|$full_name|$prefix|$repo")
    tracker_info ""
  done
fi

if [[ ${#projects[@]} -eq 0 ]]; then
  tracker_info "No projects added. You can add them later with ./add-project.sh."
  tracker_info ""
fi

declare -A seen_names=()
declare -A seen_prefixes=()

for entry in "${projects[@]}"; do
  IFS='|' read -r name full_name prefix repo_path <<< "$entry"

  tracker_project_name_valid "$name" || tracker_die "Invalid project name: $name" 2
  [[ -n "$full_name" ]] || tracker_die "Display name cannot be empty for project: $name" 2
  tracker_prefix_valid "$prefix" || tracker_die "Invalid project prefix: $prefix" 2
  tracker_require_absolute_dir "$repo_path" || tracker_die "Repo path must be an existing absolute directory: $repo_path" 2
  [[ -z "${seen_names[$name]:-}" ]] || tracker_die "Duplicate project in batch: $name" 2
  [[ -z "${seen_prefixes[$prefix]:-}" ]] || tracker_die "Duplicate prefix in batch: $prefix" 2
  [[ ! -f "$(tracker_project_file "$name")" ]] || tracker_die "Project already exists: $name" 2
  ! tracker_prefix_in_use "$prefix" || tracker_die "Project prefix already exists: $prefix" 2
  seen_names["$name"]=1
  seen_prefixes["$prefix"]=1
done

tracked_paths=()
tracked_backups=()

track_backup() {
  local target="$1"
  tracked_paths+=("$target")
  tracked_backups+=("$(tracker_backup_path "$target")")
}

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

track_backup "$TRACKER_ROOT/CLAUDE.md"
track_backup "$TRACKER_ROOT/AGENTS.md"

for entry in "${projects[@]}"; do
  IFS='|' read -r name _ _ _ <<< "$entry"
  track_backup "$(tracker_project_file "$name")"
  track_backup "$(tracker_task_dir "$name")"
  track_backup "$(tracker_archive_dir "$name")"
done

if ! tracker_ensure_base_dirs; then
  rollback_changes
  cleanup_backups
  tracker_die "Failed to create base directories" 6
fi

for entry in "${projects[@]}"; do
  IFS='|' read -r name full_name prefix repo_path <<< "$entry"
  if ! tracker_create_project_assets "$name" "$full_name" "$prefix" "$repo_path"; then
    rollback_changes
    cleanup_backups
    tracker_die "Failed to create project assets for $name" 6
  fi
  tracker_info "Created project: $name ($prefix)"
done

if ! tracker_sync_all_configs; then
  rollback_changes
  cleanup_backups
  tracker_die "Failed to sync assistant configuration files" 5
fi

if ! tracker_register_codex_skill_wrappers; then
  rollback_changes
  cleanup_backups
  tracker_die "Failed to register Codex skills" 7
fi

tracker_info ""
tracker_info "Updated CLAUDE.md project table"
tracker_info "Rendered AGENTS.md for Codex"
tracker_info "Registered $TRACKER_CODEX_SKILL_COUNT Codex skills in $TRACKER_CODEX_SKILL_DEST"

if [[ ! -d "$TRACKER_ROOT/.git" && "$skip_git_init" -eq 0 ]]; then
  init_git="Y"
  if [[ "$assume_yes" -eq 0 ]]; then
    if ! tracker_confirm "Initialize git repository?" "Y"; then
      init_git="N"
    fi
  fi

  if [[ "$init_git" =~ ^[Yy]$ ]]; then
    git init "$TRACKER_ROOT" >/dev/null
    tracker_info "Git repository initialized"
  fi
fi

cleanup_backups

tracker_info ""
tracker_info "============================================"
tracker_info "  Codex setup complete!"
tracker_info "============================================"
tracker_info ""
tracker_info "Next steps:"
tracker_info "  1. Open this repository in Codex"
tracker_info "  2. Restart Codex so it reloads skills from ~/.agents/skills"
tracker_info "  3. Use skills like task, done, today, review, plan, pulse, import, sync"
tracker_info "  4. Review AGENTS.md for vault conventions and project repo paths"
tracker_info "  5. Run ./refresh-codex-skills.sh after adding or renaming files in .claude/commands/"
tracker_info "  6. Add more projects later with ./add-project.sh"
tracker_info "  7. Remove projects with ./remove-project.sh"

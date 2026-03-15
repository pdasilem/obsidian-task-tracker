#!/usr/bin/env bash

if [[ -z "${TRACKER_ROOT:-}" ]]; then
  TRACKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

tracker_today() {
  date +%Y-%m-%d
}

tracker_now_stamp() {
  date +%Y%m%d%H%M%S
}

tracker_info() {
  printf '%s\n' "$*"
}

tracker_warn() {
  printf 'Warning: %s\n' "$*" >&2
}

tracker_error() {
  printf 'Error: %s\n' "$*" >&2
}

tracker_die() {
  local message="${1:-Unexpected error}"
  local code="${2:-1}"
  tracker_error "$message"
  exit "$code"
}

tracker_is_interactive() {
  [[ -t 0 && -t 1 ]]
}

tracker_prompt() {
  local prompt="$1"
  local default_value="${2-}"
  local reply=""

  if tracker_is_interactive; then
    if [[ -n "$default_value" ]]; then
      read -rp "$prompt [$default_value]: " reply
      printf '%s\n' "${reply:-$default_value}"
    else
      read -rp "$prompt: " reply
      printf '%s\n' "$reply"
    fi
  else
    if IFS= read -r reply; then
      printf '%s\n' "${reply:-$default_value}"
    else
      printf '%s\n' "$default_value"
    fi
  fi
}

tracker_confirm() {
  local prompt="$1"
  local default_answer="${2:-Y}"
  local reply=""

  if tracker_is_interactive; then
    read -rp "$prompt [$default_answer/n]: " reply
    reply="${reply:-$default_answer}"
  else
    if IFS= read -r reply; then
      reply="${reply:-$default_answer}"
    else
      reply="$default_answer"
    fi
  fi

  [[ "$reply" =~ ^[Yy]$ ]]
}

tracker_require_absolute_dir() {
  local dir_path="$1"
  [[ -z "$dir_path" ]] && return 0
  [[ "$dir_path" = /* ]] || return 1
  [[ -d "$dir_path" ]]
}

tracker_normalize_prefix() {
  printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]'
}

tracker_tmp_file() {
  local target="$1"
  local target_dir
  local target_name

  target_dir="$(dirname "$target")"
  target_name="$(basename "$target")"
  mkdir -p "$target_dir"
  mktemp "${target_dir}/.${target_name}.tmp.XXXXXX"
}

tracker_backup_path() {
  local target="$1"
  local backup_dir

  if [[ ! -e "$target" ]]; then
    printf '__MISSING__\n'
    return 0
  fi

  backup_dir="$(mktemp -d "${TMPDIR:-/tmp}/tracker-backup.XXXXXX")"
  cp -a "$target" "$backup_dir/item"
  printf '%s\n' "$backup_dir"
}

tracker_restore_path() {
  local target="$1"
  local backup_ref="$2"

  if [[ "$backup_ref" == "__MISSING__" ]]; then
    rm -rf "$target"
    return 0
  fi

  [[ -z "$backup_ref" ]] && return 0
  [[ -e "$backup_ref/item" ]] || return 0

  rm -rf "$target"
  cp -a "$backup_ref/item" "$target"
}

tracker_cleanup_backup() {
  local backup_ref="$1"
  [[ "$backup_ref" == "__MISSING__" ]] && return 0
  [[ -z "$backup_ref" ]] && return 0
  rm -rf "$backup_ref"
}

tracker_write_text() {
  local target="$1"
  local tmp_file

  tmp_file="$(tracker_tmp_file "$target")"
  cat > "$tmp_file"
  mv "$tmp_file" "$target"
}

tracker_ensure_base_dirs() {
  mkdir -p \
    "$TRACKER_ROOT/projects" \
    "$TRACKER_ROOT/tasks" \
    "$TRACKER_ROOT/archive" \
    "$TRACKER_ROOT/daily" \
    "$TRACKER_ROOT/weekly"
}

tracker_ensure_gitkeep() {
  local target_dir="$1"
  mkdir -p "$target_dir"
  : > "$target_dir/.gitkeep"
}

tracker_removed_projects_dir() {
  printf '%s\n' "$TRACKER_ROOT/archive/_removed_projects"
}

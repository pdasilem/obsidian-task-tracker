#!/usr/bin/env bash

tracker_repo_command_root() {
  printf '%s\n' "$TRACKER_ROOT/.claude/commands"
}

tracker_detect_host_os() {
  case "${OSTYPE:-$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')}" in
    darwin*)
      printf 'macos\n'
      ;;
    linux*)
      printf 'linux\n'
      ;;
    msys*|mingw*|cygwin*|win32*|windows_nt*)
      printf 'windows\n'
      ;;
    *)
      printf 'unknown\n'
      ;;
  esac
}

tracker_user_home_dir() {
  local host_os="$1"

  if [[ -n "${TRACKER_USER_HOME_OVERRIDE:-}" ]]; then
    printf '%s\n' "$TRACKER_USER_HOME_OVERRIDE"
    return 0
  fi

  case "$host_os" in
    windows)
      if [[ -n "${USERPROFILE:-}" ]]; then
        if command -v cygpath >/dev/null 2>&1; then
          cygpath -u "$USERPROFILE"
        else
          printf '%s\n' "$USERPROFILE"
        fi
      else
        printf '%s\n' "$HOME"
      fi
      ;;
    *)
      printf '%s\n' "$HOME"
      ;;
  esac
}

tracker_user_skill_root() {
  local host_os="$1"
  local user_home

  if [[ -n "${TRACKER_CODEX_SKILL_HOME:-}" ]]; then
    printf '%s\n' "$TRACKER_CODEX_SKILL_HOME"
    return 0
  fi

  user_home="$(tracker_user_home_dir "$host_os")"
  printf '%s\n' "$user_home/.agents/skills"
}

tracker_skill_path_supported() {
  local host_os="$1"

  case "$host_os" in
    linux|macos|windows)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

tracker_remove_path() {
  local target="$1"
  local host_os="$2"

  [[ -L "$target" ]] && rm -f "$target" && return 0
  [[ -e "$target" ]] || return 0

  case "$host_os" in
    windows)
      rm -rf "$target"
      ;;
    *)
      rm -rf "$target"
      ;;
  esac
}

tracker_skill_description() {
  case "$1" in
    task)
      printf 'Create a new task file\n'
      ;;
    done)
      printf 'Mark a task as completed\n'
      ;;
    today)
      printf "Generate or update today's daily note\n"
      ;;
    review)
      printf 'Perform an end-of-day review\n'
      ;;
    plan)
      printf 'Plan upcoming work\n'
      ;;
    pulse)
      printf 'Generate a cross-project pulse report\n'
      ;;
    import)
      printf 'Import tasks from an external list or document\n'
      ;;
    sync)
      printf 'Sync git activity across project repos\n'
      ;;
    *)
      printf 'Task Tracker workflow skill\n'
      ;;
  esac
}

tracker_render_skill_markdown() {
  local command_file="$1"
  local skill_name="$2"

  sed \
    -e 's/CLAUDE\.md/AGENTS.md/g' \
    -e "s#/${skill_name}\\([[:space:]\`\"']\\|$\\)#/skills:${skill_name}\\1#g" \
    "$command_file"
}

tracker_register_codex_skill_wrappers() {
  local host_os
  local source_root
  local dest_root
  local command_file
  local skill_name
  local skill_dir
  local skill_md_link
  local registered=0

  host_os="$(tracker_detect_host_os)"
  tracker_skill_path_supported "$host_os" || tracker_die "Unsupported host OS for Codex skill setup: $host_os" 7

  source_root="$(tracker_repo_command_root)"
  dest_root="$(tracker_user_skill_root "$host_os")"

  [[ -d "$source_root" ]] || tracker_die "Claude command directory not found: $source_root" 7

  mkdir -p "$dest_root"

  while IFS= read -r command_file; do
    skill_name="$(basename "$command_file" .md)"
    skill_dir="$dest_root/$skill_name"
    skill_md_link="$skill_dir/SKILL.md"

    mkdir -p "$skill_dir"
    tracker_remove_path "$skill_dir/agents" "$host_os"
    tracker_remove_path "$skill_dir/.task-tracker-managed" "$host_os"
    tracker_render_skill_markdown "$command_file" "$skill_name" | tracker_write_text "$skill_md_link"
    registered=$((registered + 1))
  done < <(find "$source_root" -mindepth 1 -maxdepth 1 -type f -name '*.md' | sort)

  if [[ "$registered" -eq 0 ]]; then
    tracker_die "No Claude command prompts found in: $source_root" 7
  fi

  TRACKER_CODEX_HOST_OS="$host_os"
  TRACKER_CODEX_SKILL_DEST="$dest_root"
  TRACKER_CODEX_SKILL_COUNT="$registered"
}

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

tracker_skill_link_supported() {
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

tracker_create_symlink() {
  local source_path="$1"
  local target_link="$2"
  local host_os="$3"
  local link_kind="${4:-file}"
  local mklink_flag=""
  local source_win
  local target_win

  mkdir -p "$(dirname "$target_link")"

  if [[ -L "$target_link" ]]; then
    rm -f "$target_link"
  elif [[ -e "$target_link" ]]; then
    tracker_die "Skill destination exists and is not a symlink: $target_link" 7
  fi

  case "$host_os" in
    linux|macos)
      ln -s "$source_path" "$target_link"
      ;;
    windows)
      if ln -s "$source_path" "$target_link" 2>/dev/null; then
        return 0
      fi

      command -v cygpath >/dev/null 2>&1 || return 1
      command -v cmd.exe >/dev/null 2>&1 || return 1
      source_win="$(cygpath -aw "$source_path")"
      target_win="$(cygpath -aw "$target_link")"
      if [[ "$link_kind" == "dir" ]]; then
        mklink_flag="/D"
      fi
      cmd.exe //C "mklink $mklink_flag \"$target_win\" \"$source_win\"" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

tracker_render_skill_openai_yaml() {
  local skill_name="$1"
  local short_description="$2"

  cat <<EOF
interface:
  display_name: "${skill_name}"
  short_description: "${short_description}"
EOF
}

tracker_skill_marker_name() {
  printf '.task-tracker-managed\n'
}

tracker_mark_skill_dir() {
  local skill_dir="$1"
  : > "$skill_dir/$(tracker_skill_marker_name)"
}

tracker_is_managed_skill_dir() {
  local skill_dir="$1"
  [[ -f "$skill_dir/$(tracker_skill_marker_name)" ]]
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

tracker_remove_stale_codex_skill_wrappers() {
  local dest_root="$1"
  local host_os="$2"
  local skill_dir
  local skill_name

  [[ -d "$dest_root" ]] || return 0

  while IFS= read -r skill_dir; do
    tracker_is_managed_skill_dir "$skill_dir" || continue
    skill_name="$(basename "$skill_dir")"
    [[ -f "$(tracker_repo_command_root)/$skill_name.md" ]] && continue
    tracker_remove_path "$skill_dir" "$host_os"
  done < <(find "$dest_root" -mindepth 1 -maxdepth 1 -type d | sort)
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

tracker_register_codex_skill_wrappers() {
  local host_os
  local source_root
  local dest_root
  local command_file
  local skill_name
  local skill_dir
  local skill_md_link
  local agents_dir
  local openai_yaml
  local registered=0

  host_os="$(tracker_detect_host_os)"
  tracker_skill_link_supported "$host_os" || tracker_die "Unsupported host OS for Codex skill setup: $host_os" 7

  source_root="$(tracker_repo_command_root)"
  dest_root="$(tracker_user_skill_root "$host_os")"

  [[ -d "$source_root" ]] || tracker_die "Claude command directory not found: $source_root" 7

  mkdir -p "$dest_root"
  tracker_remove_stale_codex_skill_wrappers "$dest_root" "$host_os"

  while IFS= read -r command_file; do
    skill_name="$(basename "$command_file" .md)"
    skill_dir="$dest_root/$skill_name"
    skill_md_link="$skill_dir/SKILL.md"
    agents_dir="$skill_dir/agents"
    openai_yaml="$agents_dir/openai.yaml"

    mkdir -p "$skill_dir" "$agents_dir"
    tracker_mark_skill_dir "$skill_dir"
    tracker_create_symlink "$command_file" "$skill_md_link" "$host_os" "file" || {
      tracker_die "Failed to register Codex skill prompt: $skill_name" 7
    }
    tracker_render_skill_openai_yaml "$skill_name" "$(tracker_skill_description "$skill_name")" | tracker_write_text "$openai_yaml"
    registered=$((registered + 1))
  done < <(find "$source_root" -mindepth 1 -maxdepth 1 -type f -name '*.md' | sort)

  if [[ "$registered" -eq 0 ]]; then
    tracker_die "No Claude command prompts found in: $source_root" 7
  fi

  TRACKER_CODEX_HOST_OS="$host_os"
  TRACKER_CODEX_SKILL_DEST="$dest_root"
  TRACKER_CODEX_SKILL_COUNT="$registered"
}

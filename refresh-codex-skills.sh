#!/usr/bin/env bash
set -euo pipefail

TRACKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TRACKER_ROOT/scripts/lib/common.sh"
source "$TRACKER_ROOT/scripts/lib/codex_skills.sh"

tracker_info "============================================"
tracker_info "  Obsidian Task Tracker — Codex Skill Refresh"
tracker_info "============================================"
tracker_info ""
tracker_info "Vault path: $TRACKER_ROOT"

tracker_register_codex_skill_wrappers

tracker_info ""
tracker_info "Registered $TRACKER_CODEX_SKILL_COUNT Codex skills in $TRACKER_CODEX_SKILL_DEST"
tracker_info "Detected host OS: $TRACKER_CODEX_HOST_OS"
tracker_info "Restart Codex to reload the refreshed skills."

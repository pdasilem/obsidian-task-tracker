#!/usr/bin/env bash
set -euo pipefail

# Obsidian Task Tracker — Interactive Setup
# Creates project folders, configures CLAUDE.md, and initializes git.

VAULT_PATH="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  Obsidian Task Tracker — Setup"
echo "============================================"
echo ""
echo "Vault path: $VAULT_PATH"
echo ""

# --- Update vault_path in CLAUDE.md ---
if [[ -f "$VAULT_PATH/CLAUDE.md" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s|^vault_path:.*|vault_path: $VAULT_PATH|" "$VAULT_PATH/CLAUDE.md"
  else
    sed -i "s|^vault_path:.*|vault_path: $VAULT_PATH|" "$VAULT_PATH/CLAUDE.md"
  fi
  echo "Updated vault_path in CLAUDE.md"
else
  echo "Warning: CLAUDE.md not found"
fi

# --- Collect project names ---
echo ""
echo "Enter your project names (one per line, lowercase, no spaces)."
echo "For each project you'll also set a display name, ID prefix, and optional repo path."
echo "Press Enter on an empty line when done."
echo ""

projects=()
while true; do
  read -rp "Project name (or Enter to finish): " name
  [[ -z "$name" ]] && break

  read -rp "  Display name [$name]: " full_name
  full_name="${full_name:-$name}"

  # Suggest prefix from name (first 3-4 chars uppercase)
  suggested_prefix=$(echo "$name" | tr '[:lower:]' '[:upper:]' | cut -c1-3)
  read -rp "  ID prefix [$suggested_prefix]: " prefix
  prefix="${prefix:-$suggested_prefix}"
  prefix=$(echo "$prefix" | tr '[:lower:]' '[:upper:]')

  read -rp "  Git repo path (optional, Enter to skip): " repo

  projects+=("$name|$full_name|$prefix|$repo")
  echo ""
done

if [[ ${#projects[@]} -eq 0 ]]; then
  echo "No projects added. You can add them later by creating files in projects/ and tasks/."
  echo ""
fi

# --- Create project files and directories ---
TABLE_ROWS=""

for entry in "${projects[@]}"; do
  IFS='|' read -r name full_name prefix repo <<< "$entry"

  # Create task directory
  mkdir -p "$VAULT_PATH/tasks/$name"
  touch "$VAULT_PATH/tasks/$name/.gitkeep"

  # Create archive directory
  mkdir -p "$VAULT_PATH/archive/$name"
  touch "$VAULT_PATH/archive/$name/.gitkeep"

  # Create project file
  cat > "$VAULT_PATH/projects/$name.md" << PROJ
---
project: $name
full_name: $full_name
repo: $repo
remote:
status: active
started: $(date +%Y-%m-%d)
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
PROJ

  # Build table row for CLAUDE.md
  TABLE_ROWS+="| $name | $repo | $prefix |\n"
  echo "Created project: $name ($prefix)"
done

# --- Update CLAUDE.md project table ---
if [[ -n "$TABLE_ROWS" && -f "$VAULT_PATH/CLAUDE.md" ]]; then
  # Insert rows after the table header
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "/^| Project | Repo Path | ID Prefix |/,/^$/{
      /^|---------|-----------|-----------|$/a\\
$(echo -e "$TABLE_ROWS" | sed 's/$/\\/')
    }" "$VAULT_PATH/CLAUDE.md"
  else
    sed -i "/^|---------|-----------|-----------|$/a\\
$(echo -e "$TABLE_ROWS")" "$VAULT_PATH/CLAUDE.md"
  fi
  echo ""
  echo "Updated project table in CLAUDE.md"
fi

# --- Ensure base directories exist ---
mkdir -p "$VAULT_PATH/daily" "$VAULT_PATH/weekly" "$VAULT_PATH/archive"

# --- Initialize git ---
if [[ ! -d "$VAULT_PATH/.git" ]]; then
  echo ""
  read -rp "Initialize git repository? [Y/n]: " init_git
  init_git="${init_git:-Y}"
  if [[ "$init_git" =~ ^[Yy] ]]; then
    git init "$VAULT_PATH"
    echo "Git repository initialized"
  fi
fi

echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Open this folder as an Obsidian vault"
echo "  2. Install community plugins: Dataview, Templater, Periodic Notes,"
echo "     Calendar, Kanban, Tasks"
echo "  3. Configure Templater: set template folder to 'templates/'"
echo "  4. Configure Periodic Notes:"
echo "     - Daily: format 'YYYY/MM/YYYY-MM-DD', folder 'daily/'"
echo "     - Weekly: format 'YYYY/YYYY-[W]WW', folder 'weekly/'"
echo "  5. Start tracking: claude /task \"My first task\" --project <name>"
echo ""
echo "You can safely delete projects/_example.md and tasks/_example/"
echo "once you've created your own projects."

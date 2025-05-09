#!/bin/bash
set -euo pipefail

echo "🔍 Resolving project name from multiple layers..."

PROJECT_DEFAULTS_FILE="${DEFAULTS_FILE_OVERRIDE:-.github/config/defaults.json}"
ACTION_DEFAULTS_FILE="${ACTION_DEFAULTS_FILE:-$GITHUB_ACTION_PATH/defaults.json}"

if [[ ! -f "$PROJECT_DEFAULTS_FILE" ]]; then
  echo "⚠️ Project defaults file not found at $PROJECT_DEFAULTS_FILE."
fi

if [[ ! -f "$ACTION_DEFAULTS_FILE" ]]; then
  echo "❌ Action defaults file not found at $ACTION_DEFAULTS_FILE. Exiting."
  exit 1
fi

PROJECT_DEFAULTS=$( [[ -f "$PROJECT_DEFAULTS_FILE" ]] && cat "$PROJECT_DEFAULTS_FILE" || echo '{}' )
ACTION_DEFAULTS=$(cat "$ACTION_DEFAULTS_FILE")

PROJECT_DEFAULT_NAME=$(echo "$PROJECT_DEFAULTS" | jq -r '.project.name // empty')
ACTION_DEFAULT_NAME=$(echo "$ACTION_DEFAULTS" | jq -r '.project.name // empty')

# ─────────────────────────────────────────────────────────────
# Layered resolution
# ─────────────────────────────────────────────────────────────

if [[ -n "$INPUT_NAME" ]]; then
  FINAL_NAME="$INPUT_NAME"
  echo "✅ Using project name from input: $FINAL_NAME"
elif [[ -n "$REPO_VAR_NAME" ]]; then
  FINAL_NAME="$REPO_VAR_NAME"
  echo "✅ Using project name from repo var: $FINAL_NAME"
elif [[ -n "$PROJECT_DEFAULT_NAME" ]]; then
  FINAL_NAME="$PROJECT_DEFAULT_NAME"
  echo "✅ Using project name from project defaults.json: $FINAL_NAME"
elif [[ -n "$ACTION_DEFAULT_NAME" ]]; then
  FINAL_NAME="$ACTION_DEFAULT_NAME"
  echo "✅ Using project name from action fallback defaults.json: $FINAL_NAME"
else
  echo "❌ No valid project name could be resolved."
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# Sanitize name
# ─────────────────────────────────────────────────────────────

RAW_NAME="$(echo "$FINAL_NAME" | xargs)"
SANITIZED_NAME="$(echo "$RAW_NAME" | sed 's/[^a-zA-Z0-9._-]/_/g')"

echo "🔹 Raw Name       : $RAW_NAME"
echo "🔹 Sanitized Name : $SANITIZED_NAME"

# Output
echo "sanitized_name=$SANITIZED_NAME" >> "$GITHUB_OUTPUT"

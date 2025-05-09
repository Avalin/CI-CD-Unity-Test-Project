#!/bin/bash
set -euo pipefail

echo "🔍 Resolving test config from multiple layers..."

# Load defaults
PROJECT_DEFAULTS_FILE="${PROJECT_DEFAULTS_FILE:-.github/config/defaults.json}"
ACTION_DEFAULTS_FILE="${ACTION_DEFAULTS_FILE:-$GITHUB_ACTION_PATH/defaults.json}"

[[ ! -f "$PROJECT_DEFAULTS_FILE" ]] && echo "⚠️ Project defaults not found: $PROJECT_DEFAULTS_FILE"
[[ ! -f "$ACTION_DEFAULTS_FILE" ]] && { echo "❌ Action fallback defaults not found: $ACTION_DEFAULTS_FILE"; exit 1; }

PROJECT_DEFAULTS=$( [[ -f "$PROJECT_DEFAULTS_FILE" ]] && cat "$PROJECT_DEFAULTS_FILE" || echo '{}' )
ACTION_DEFAULTS=$(cat "$ACTION_DEFAULTS_FILE")

# Project & Action fallback values (new structure)
PROJECT_EDIT_MODE_PATH=$(echo "$PROJECT_DEFAULTS" | jq -r '.tests.editMode.path // empty')
PROJECT_PLAY_MODE_PATH=$(echo "$PROJECT_DEFAULTS" | jq -r '.tests.playMode.path // empty')

ACTION_EDIT_MODE_PATH=$(echo "$ACTION_DEFAULTS" | jq -r '.tests.editMode.path // "Assets/Tests/Editor"')
ACTION_PLAY_MODE_PATH=$(echo "$ACTION_DEFAULTS" | jq -r '.tests.playMode.path // "Assets/Tests/PlayMode"')

# Layered resolution
EDIT_MODE_PATH="${EDIT_MODE_PATH_INPUT:-${EDIT_MODE_PATH_REPO_VAR:-${PROJECT_EDIT_MODE_PATH:-$ACTION_EDIT_MODE_PATH}}}"
PLAY_MODE_PATH="${PLAY_MODE_PATH_INPUT:-${PLAY_MODE_PATH_REPO_VAR:-${PROJECT_PLAY_MODE_PATH:-$ACTION_PLAY_MODE_PATH}}}"

# Export outputs
echo "editModePath=$EDIT_MODE_PATH" >> "$GITHUB_OUTPUT"
echo "playModePath=$PLAY_MODE_PATH" >> "$GITHUB_OUTPUT"

echo "✅ Test config resolved successfully."

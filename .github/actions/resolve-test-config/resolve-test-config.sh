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

# Project & Action fallback values
PROJECT_USE_GIT_LFS=$(echo "$PROJECT_DEFAULTS" | jq -r '.unity.useGitLfs // empty')
PROJECT_EDIT_MODE_PATH=$(echo "$PROJECT_DEFAULTS" | jq -r '.unityTests.editModePath // empty')
PROJECT_PLAY_MODE_PATH=$(echo "$PROJECT_DEFAULTS" | jq -r '.unityTests.playModePath // empty')
PROJECT_QUIET_MODE=$(echo "$PROJECT_DEFAULTS" | jq -r '.unity.quietMode // empty')

ACTION_USE_GIT_LFS=$(echo "$ACTION_DEFAULTS" | jq -r '.unity.useGitLfs // false')
ACTION_EDIT_MODE_PATH=$(echo "$ACTION_DEFAULTS" | jq -r '.unityTests.editModePath // "Assets/Tests/Editor"')
ACTION_PLAY_MODE_PATH=$(echo "$ACTION_DEFAULTS" | jq -r '.unityTests.playModePath // "Assets/Tests/PlayMode"')
ACTION_QUIET_MODE=$(echo "$ACTION_DEFAULTS" | jq -r '.unity.quietMode // false')

# Layered resolution
USE_GIT_LFS="${USE_GIT_LFS_INPUT:-${USE_GIT_LFS_REPO_VAR:-${PROJECT_USE_GIT_LFS:-$ACTION_USE_GIT_LFS}}}"
EDIT_MODE_PATH="${EDIT_MODE_PATH_INPUT:-${EDIT_MODE_PATH_REPO_VAR:-${PROJECT_EDIT_MODE_PATH:-$ACTION_EDIT_MODE_PATH}}}"
PLAY_MODE_PATH="${PLAY_MODE_PATH_INPUT:-${PLAY_MODE_PATH_REPO_VAR:-${PROJECT_PLAY_MODE_PATH:-$ACTION_PLAY_MODE_PATH}}}"
QUIET_MODE="${QUIET_MODE_INPUT:-${QUIET_MODE_REPO_VAR:-${PROJECT_QUIET_MODE:-$ACTION_QUIET_MODE}}}"

# Export outputs
echo "useGitLfs=$USE_GIT_LFS" >> "$GITHUB_OUTPUT"
echo "editModePath=$EDIT_MODE_PATH" >> "$GITHUB_OUTPUT"
echo "playModePath=$PLAY_MODE_PATH" >> "$GITHUB_OUTPUT"
echo "quietMode=$QUIET_MODE" >> "$GITHUB_OUTPUT"

# Step summary
echo "## 📋 Test Config Summary" >> "$GITHUB_STEP_SUMMARY"
echo "| Key             | Value             |" >> "$GITHUB_STEP_SUMMARY"
echo "|-----------------|-------------------|" >> "$GITHUB_STEP_SUMMARY"
echo "| Use Git LFS     | $USE_GIT_LFS      |" >> "$GITHUB_STEP_SUMMARY"
echo "| EditMode Path   | $EDIT_MODE_PATH   |" >> "$GITHUB_STEP_SUMMARY"
echo "| PlayMode Path   | $PLAY_MODE_PATH   |" >> "$GITHUB_STEP_SUMMARY"
echo "| Quiet Mode      | $QUIET_MODE       |" >> "$GITHUB_STEP_SUMMARY"

echo "✅ Test config resolved successfully."
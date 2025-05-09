#!/bin/bash
set -euo pipefail

echo "🔍 Resolving CI options from multiple layers..."

# Paths to defaults
PROJECT_DEFAULTS_FILE="${PROJECT_DEFAULTS_FILE:-.github/config/defaults.json}"
ACTION_DEFAULTS_FILE="${ACTION_DEFAULTS_FILE:-$GITHUB_ACTION_PATH/defaults.json}"

# Load project defaults if present
if [[ -f "$PROJECT_DEFAULTS_FILE" ]]; then
  PROJECT_DEFAULTS=$(cat "$PROJECT_DEFAULTS_FILE")
else
  echo "⚠️ Project defaults not found at $PROJECT_DEFAULTS_FILE"
  PROJECT_DEFAULTS="{}"
fi

# Load action-fallback defaults (must exist)
if [[ ! -f "$ACTION_DEFAULTS_FILE" ]]; then
  echo "❌ Action defaults not found at $ACTION_DEFAULTS_FILE"
  exit 1
fi
ACTION_DEFAULTS=$(cat "$ACTION_DEFAULTS_FILE")

# Pull out each flag from project & action defaults
PROJECT_USE_GIT_LFS=$(echo "$PROJECT_DEFAULTS" | jq -r '.pipeline.useGitLfs // empty')
PROJECT_QUIET_MODE=$(echo "$PROJECT_DEFAULTS" | jq -r '.pipeline.quietMode // empty')
PROJECT_EXCLUDE_TESTS=$(echo "$PROJECT_DEFAULTS" | jq -r '.pipeline.excludeUnityTests // empty')
PROJECT_FORCE_COMBINE=$(echo "$PROJECT_DEFAULTS" | jq -r '.pipeline.forceCombineArtifacts // empty')

ACTION_USE_GIT_LFS=$(echo "$ACTION_DEFAULTS" | jq -r '.pipeline.useGitLfs // empty')
ACTION_QUIET_MODE=$(echo "$ACTION_DEFAULTS" | jq -r '.pipeline.quietMode // empty')
ACTION_EXCLUDE_TESTS=$(echo "$ACTION_DEFAULTS" | jq -r '.pipeline.excludeUnityTests // empty')
ACTION_FORCE_COMBINE=$(echo "$ACTION_DEFAULTS" | jq -r '.pipeline.forceCombineArtifacts // empty')

# Helper: first non-empty, must be “true” or “false”
resolve_flag() {
  local input_val="$1" repo_val="$2" proj_val="$3" act_val="$4" name="$5"
  for val in "$input_val" "$repo_val" "$proj_val" "$act_val"; do
    if [[ -n "$val" ]]; then
      case "${val,,}" in
        true|false) echo "$val"; return ;;
        *) echo "⚠️ Invalid $name: $val" >&2 ;;
      esac
    fi
  done
  echo "false"
}

USE_GIT_LFS=$(resolve_flag "$USE_GIT_LFS_INPUT" "$USE_GIT_LFS_REPO_VAR" "$PROJECT_USE_GIT_LFS" "$ACTION_USE_GIT_LFS" "useGitLfs")
QUIET_MODE=$(resolve_flag "$QUIET_MODE_INPUT" "$QUIET_MODE_REPO_VAR" "$PROJECT_QUIET_MODE" "$ACTION_QUIET_MODE" "quietMode")
EXCLUDE_TESTS=$(resolve_flag "$EXCLUDE_UNITY_TESTS_INPUT" "$EXCLUDE_UNITY_TESTS_REPO_VAR" "$PROJECT_EXCLUDE_TESTS" "$ACTION_EXCLUDE_TESTS" "excludeUnityTests")
FORCE_COMBINE=$(resolve_flag "$FORCE_COMBINE_ARTIFACTS_INPUT" "$FORCE_COMBINE_ARTIFACTS_REPO_VAR" "$PROJECT_FORCE_COMBINE" "$ACTION_FORCE_COMBINE" "forceCombineArtifacts")

# Export outputs
{
  echo "useGitLfs=$USE_GIT_LFS"
  echo "quietMode=$QUIET_MODE"
  echo "excludeUnityTests=$EXCLUDE_TESTS"
  echo "forceCombineArtifacts=$FORCE_COMBINE"
} >> "$GITHUB_OUTPUT"

echo "✅ CI options resolved."
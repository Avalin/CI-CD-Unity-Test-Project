#!/bin/bash
set -e

echo "🔍 Resolving retention days from multiple layers..."

# Inputs
BUILD_TYPE="$1"

# Load config files
PROJECT_DEFAULTS_FILE="${INPUT_DEFAULTS_FILE_OVERRIDE:-.github/config/defaults.json}"
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

# Select values based on build type
case "$BUILD_TYPE" in
  release)
    INPUT_OVERRIDE="$INPUT_RETENTION_DAYS_RELEASE_OVERRIDE"
    REPO_VAR="$INPUT_RETENTION_DAYS_RELEASE_REPO_VAR"
    PROJECT_DEFAULT_VALUE=$(echo "$PROJECT_DEFAULTS" | jq -r '.build.retentionDays.release // empty')
    ACTION_DEFAULT_VALUE=$(echo "$ACTION_DEFAULTS" | jq -r '.build.retentionDays.release // empty')
    ;;
  release_candidate)
    INPUT_OVERRIDE="$INPUT_RETENTION_DAYS_RC_OVERRIDE"
    REPO_VAR="$INPUT_RETENTION_DAYS_RC_REPO_VAR"
    PROJECT_DEFAULT_VALUE=$(echo "$PROJECT_DEFAULTS" | jq -r '.build.retentionDays.release_candidate // empty')
    ACTION_DEFAULT_VALUE=$(echo "$ACTION_DEFAULTS" | jq -r '.build.retentionDays.release_candidate // empty')
    ;;
  preview | *)
    INPUT_OVERRIDE="$INPUT_RETENTION_DAYS_PREVIEW_OVERRIDE"
    REPO_VAR="$INPUT_RETENTION_DAYS_PREVIEW_REPO_VAR"
    PROJECT_DEFAULT_VALUE=$(echo "$PROJECT_DEFAULTS" | jq -r '.build.retentionDays.preview // empty')
    ACTION_DEFAULT_VALUE=$(echo "$ACTION_DEFAULTS" | jq -r '.build.retentionDays.preview // empty')
    ;;
esac

# Validate function
validate_retention_days() {
  local val="$1"
  if [[ "$val" =~ ^[0-9]+$ && "$val" -gt 0 ]]; then
    echo "$val"
    return 0
  fi
  return 1
}

# ─────────────────────────────────────────────────────────────
# Step 1: Check input override
# ─────────────────────────────────────────────────────────────
if [[ -n "$INPUT_OVERRIDE" ]]; then
  if resolved=$(validate_retention_days "$INPUT_OVERRIDE"); then
    echo "✅ Using retentionDays from input override: $resolved"
    echo "retentionDays=$resolved" >> "$GITHUB_OUTPUT"
    exit 0
  else
    echo "⚠️ Input override retentionDays invalid: $INPUT_OVERRIDE"
  fi
fi

# ─────────────────────────────────────────────────────────────
# Step 2: Check repo var
# ─────────────────────────────────────────────────────────────
if [[ -n "$REPO_VAR" ]]; then
  if resolved=$(validate_retention_days "$REPO_VAR"); then
    echo "✅ Using retentionDays from repo var: $resolved"
    echo "retentionDays=$resolved" >> "$GITHUB_OUTPUT"
    exit 0
  else
    echo "⚠️ Repo var retentionDays invalid: $REPO_VAR"
  fi
fi

# ─────────────────────────────────────────────────────────────
# Step 3: Check project config
# ─────────────────────────────────────────────────────────────
if [[ -n "$PROJECT_DEFAULT_VALUE" ]]; then
  if resolved=$(validate_retention_days "$PROJECT_DEFAULT_VALUE"); then
    echo "✅ Using retentionDays from project config: $resolved"
    echo "retentionDays=$resolved" >> "$GITHUB_OUTPUT"
    exit 0
  else
    echo "⚠️ Project config retentionDays invalid: $PROJECT_DEFAULT_VALUE"
  fi
fi

# ─────────────────────────────────────────────────────────────
# Step 4: Check action fallback config
# ─────────────────────────────────────────────────────────────
if [[ -n "$ACTION_DEFAULT_VALUE" ]]; then
  if resolved=$(validate_retention_days "$ACTION_DEFAULT_VALUE"); then
    echo "✅ Using retentionDays from action fallback: $resolved"
    echo "retentionDays=$resolved" >> "$GITHUB_OUTPUT"
    exit 0
  else
    echo "❌ Action fallback retentionDays invalid: $ACTION_DEFAULT_VALUE"
    exit 1
  fi
fi

# ─────────────────────────────────────────────────────────────
# Fail if none resolved
# ─────────────────────────────────────────────────────────────
echo "❌ No valid retentionDays could be resolved."
exit 1
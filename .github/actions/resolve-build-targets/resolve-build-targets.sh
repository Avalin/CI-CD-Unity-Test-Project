#!/bin/bash
set -euo pipefail

echo "🔍 Resolving build targets from multiple layers..."

PROJECT_DEFAULTS_FILE="${PROJECT_DEFAULTS_FILE:-.github/config/defaults.json}"
ACTION_DEFAULTS_FILE="${ACTION_DEFAULTS_FILE:-${GITHUB_ACTION_PATH}/defaults.json}"
PROJECT_BUILD_TARGETS_FILE="${PROJECT_BUILD_TARGETS_FILE:-.github/config/build-targets.json}"
ACTION_BUILD_TARGETS_FILE="${ACTION_BUILD_TARGETS_FILE:-${GITHUB_ACTION_PATH}/build-targets.json}"

# Validate defaults.json files
if [[ ! -f "$PROJECT_DEFAULTS_FILE" ]]; then
  echo "⚠️ Local defaults.json not found: $PROJECT_DEFAULTS_FILE"
fi

if [[ ! -f "$ACTION_DEFAULTS_FILE" ]]; then
  echo "❌ Action defaults.json not found: $ACTION_DEFAULTS_FILE"
  exit 1
fi

# Load project + action defaults
PROJECT_DEFAULTS=$( [[ -f "$PROJECT_DEFAULTS_FILE" ]] && cat "$PROJECT_DEFAULTS_FILE" || echo '{}' )
ACTION_DEFAULTS=$(cat "$ACTION_DEFAULTS_FILE")

PROJECT_DEFAULT_TARGETS=$(echo "$PROJECT_DEFAULTS" | jq -c '.build.defaultTargets // empty')
ACTION_DEFAULT_TARGETS=$(echo "$ACTION_DEFAULTS" | jq -c '.build.defaultTargets // empty')

# Step 1: Direct input
if [[ -n "$BUILDTARGETS_INPUT" && "$BUILDTARGETS_INPUT" != "null" ]]; then
  RESOLVED_TARGETS="$BUILDTARGETS_INPUT"
  echo "✅ Using build targets from input: $RESOLVED_TARGETS"

# Step 2: Repo var
elif [[ -n "$BUILDTARGETS_REPOVAR" && "$BUILDTARGETS_REPOVAR" != "null" ]]; then
  RESOLVED_TARGETS="$BUILDTARGETS_REPOVAR"
  echo "✅ Using build targets from repo var: $RESOLVED_TARGETS"

# Step 3: Project defaults.json
elif [[ -n "$PROJECT_DEFAULT_TARGETS" && "$PROJECT_DEFAULT_TARGETS" != "null" ]]; then
  RESOLVED_TARGETS="$PROJECT_DEFAULT_TARGETS"
  echo "✅ Using build targets from local defaults: $RESOLVED_TARGETS"

# Step 4: Action fallback defaults.json
elif [[ -n "$ACTION_DEFAULT_TARGETS" && "$ACTION_DEFAULT_TARGETS" != "null" ]]; then
  RESOLVED_TARGETS="$ACTION_DEFAULT_TARGETS"
  echo "✅ Using build targets from action fallback defaults: $RESOLVED_TARGETS"

else
  echo "❌ No valid build targets could be resolved."
  exit 1
fi

# Select build-targets.json for validation rules
if [ -f "$PROJECT_BUILD_TARGETS_FILE" ]; then
  echo "✅ Using local build-targets.json: $PROJECT_BUILD_TARGETS_FILE"
  VALIDATION_CONFIG="$PROJECT_BUILD_TARGETS_FILE"
elif [ -f "$ACTION_BUILD_TARGETS_FILE" ]; then
  echo "✅ Using action fallback build-targets.json: $ACTION_BUILD_TARGETS_FILE"
  VALIDATION_CONFIG="$ACTION_BUILD_TARGETS_FILE"
else
  echo "❌ No valid build-targets.json found."
  exit 1
fi

# Resolve minimum build type weights
type_weight() {
  case "$1" in
    preview) echo 1 ;;
    release_candidate) echo 2 ;;
    release) echo 3 ;;
    *) echo 0 ;;
  esac
}

BUILD_WEIGHT=$(type_weight "$BUILD_TYPE")
VALIDATED="[]"

for TARGET in $(echo "$RESOLVED_TARGETS" | jq -r '.[]'); do
  if jq -e --arg p "$TARGET" '.[$p]' "$VALIDATION_CONFIG" >/dev/null; then
    MIN_TYPE=$(jq -r --arg p "$TARGET" '.[$p].minimumBuildType' "$VALIDATION_CONFIG")
    MIN_WEIGHT=$(type_weight "$MIN_TYPE")

    if [ "$BUILD_WEIGHT" -ge "$MIN_WEIGHT" ]; then
      VALIDATED=$(echo "$VALIDATED" | jq --arg p "$TARGET" '. + [$p]')
    else
      echo "⚠️ Skipping $TARGET — requires minimum build type $MIN_TYPE"
    fi
  else
    echo "⚠️ Unknown build target $TARGET — skipping"
  fi
done

echo "✅ Final validated build targets: $VALIDATED"

echo "validatedBuildTargets<<EOF" >> "$GITHUB_OUTPUT"
echo "$VALIDATED" >> "$GITHUB_OUTPUT"
echo "EOF" >> "$GITHUB_OUTPUT"
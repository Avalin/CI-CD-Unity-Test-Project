#!/bin/bash
set -e

echo "🔍 Resolving timeouts from multiple layers..."

# Load config files
PROJECT_DEFAULTS_FILE="${PROJECT_DEFAULTS_FILE:-.github/config/defaults.json}"
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

# Updated selectors
PROJECT_TESTS_TIMEOUT=$(echo "$PROJECT_DEFAULTS" | jq -r '.tests.timeoutMinutes // empty')
PROJECT_BUILD_TIMEOUT=$(echo "$PROJECT_DEFAULTS" | jq -r '.build.timeoutMinutes // empty')
ACTION_TESTS_TIMEOUT=$(echo "$ACTION_DEFAULTS" | jq -r '.tests.timeoutMinutes // empty')
ACTION_BUILD_TIMEOUT=$(echo "$ACTION_DEFAULTS" | jq -r '.build.timeoutMinutes // empty')

validate_timeout() {
  local val="$1"
  if [[ "$val" =~ ^[0-9]+$ && "$val" -gt 0 ]]; then
    echo "$val"
    return 0
  fi
  return 1
}

# Resolve test timeout
if [[ -n "$TIMEOUT_TESTS_INPUT" ]]; then
  if resolved=$(validate_timeout "$TIMEOUT_TESTS_INPUT"); then
    echo "✅ Using test timeout from input: $resolved"
    timeoutTests="$resolved"
  else
    echo "⚠️ Invalid test timeout input: $TIMEOUT_TESTS_INPUT"
  fi
fi

if [[ -z "$timeoutTests" && -n "$TIMEOUT_TESTS_REPO_VAR" ]]; then
  if resolved=$(validate_timeout "$TIMEOUT_TESTS_REPO_VAR"); then
    echo "✅ Using test timeout from repo var: $resolved"
    timeoutTests="$resolved"
  else
    echo "⚠️ Invalid test timeout repo var: $TIMEOUT_TESTS_REPO_VAR"
  fi
fi

if [[ -z "$timeoutTests" && -n "$PROJECT_TESTS_TIMEOUT" ]]; then
  if resolved=$(validate_timeout "$PROJECT_TESTS_TIMEOUT"); then
    echo "✅ Using test timeout from project config: $resolved"
    timeoutTests="$resolved"
  else
    echo "⚠️ Invalid project test timeout: $PROJECT_TESTS_TIMEOUT"
  fi
fi

if [[ -z "$timeoutTests" && -n "$ACTION_TESTS_TIMEOUT" ]]; then
  if resolved=$(validate_timeout "$ACTION_TESTS_TIMEOUT"); then
    echo "✅ Using test timeout from action fallback: $resolved"
    timeoutTests="$resolved"
  else
    echo "❌ Invalid action fallback test timeout: $ACTION_TESTS_TIMEOUT"
    exit 1
  fi
fi

# Resolve build timeout
if [[ -n "$TIMEOUT_BUILD_INPUT" ]]; then
  if resolved=$(validate_timeout "$TIMEOUT_BUILD_INPUT"); then
    echo "✅ Using build timeout from input: $resolved"
    timeoutBuild="$resolved"
  else
    echo "⚠️ Invalid build timeout input: $TIMEOUT_BUILD_INPUT"
  fi
fi

if [[ -z "$timeoutBuild" && -n "$TIMEOUT_BUILD_REPO_VAR" ]]; then
  if resolved=$(validate_timeout "$TIMEOUT_BUILD_REPO_VAR"); then
    echo "✅ Using build timeout from repo var: $resolved"
    timeoutBuild="$resolved"
  else
    echo "⚠️ Invalid build timeout repo var: $TIMEOUT_BUILD_REPO_VAR"
  fi
fi

if [[ -z "$timeoutBuild" && -n "$PROJECT_BUILD_TIMEOUT" ]]; then
  if resolved=$(validate_timeout "$PROJECT_BUILD_TIMEOUT"); then
    echo "✅ Using build timeout from project config: $resolved"
    timeoutBuild="$resolved"
  else
    echo "⚠️ Invalid project build timeout: $PROJECT_BUILD_TIMEOUT"
  fi
fi

if [[ -z "$timeoutBuild" && -n "$ACTION_BUILD_TIMEOUT" ]]; then
  if resolved=$(validate_timeout "$ACTION_BUILD_TIMEOUT"); then
    echo "✅ Using build timeout from action fallback: $resolved"
    timeoutBuild="$resolved"
  else
    echo "❌ Invalid action fallback build timeout: $ACTION_BUILD_TIMEOUT"
    exit 1
  fi
fi

# Final outputs
echo "timeoutMinutesTests=$timeoutTests" >> "$GITHUB_OUTPUT"
echo "timeoutMinutesBuild=$timeoutBuild" >> "$GITHUB_OUTPUT"

echo "✅ Final resolved test timeout: $timeoutTests minutes"
echo "✅ Final resolved build timeout: $timeoutBuild minutes"
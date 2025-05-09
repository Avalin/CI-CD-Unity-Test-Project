  #!/bin/bash
  set -e

  echo "🔍 Resolving Unity version from multiple layers..."

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

  # Load defaults
  PROJECT_DEFAULTS=$( [[ -f "$PROJECT_DEFAULTS_FILE" ]] && cat "$PROJECT_DEFAULTS_FILE" || echo '{}' )
  ACTION_DEFAULTS=$(cat "$ACTION_DEFAULTS_FILE")

  # Extract default values
  PROJECT_DEFAULT_UNITY=$(echo "$PROJECT_DEFAULTS" | jq -r '.unity.version // empty')
  ACTION_DEFAULT_UNITY=$(echo "$ACTION_DEFAULTS" | jq -r '.unity.version // empty')

  # Validate function
  validate_unity_version() {
    local val="$1"
    if [[ "$val" == "auto" ]]; then
      echo "auto"
      return 0
    fi
    if [[ "$val" =~ ^[0-9]+\.[0-9]+\.[0-9]+(f[0-9]+|p[0-9]+|b[0-9]+|a[0-9]+)?$ ]]; then
      echo "$val"
      return 0
    fi
    return 1
  }

  # ─────────────────────────────────────────────────────────────
  # Step 1: Check input override
  # ─────────────────────────────────────────────────────────────
  if [[ -n "$UNITY_VERSION_INPUT" ]]; then
    if resolved=$(validate_unity_version "$UNITY_VERSION_INPUT"); then
      echo "✅ Using unityVersion from input: $resolved"
      echo "unityVersion=$resolved" >> "$GITHUB_OUTPUT"
      exit 0
    else
      echo "⚠️ Input unityVersion invalid: $UNITY_VERSION_INPUT"
    fi
  fi

  # ─────────────────────────────────────────────────────────────
  # Step 2: Check repo var
  # ─────────────────────────────────────────────────────────────
  if [[ -n "$UNITY_VERSION_REPO_VAR" ]]; then
    if resolved=$(validate_unity_version "$UNITY_VERSION_REPO_VAR"); then
      echo "✅ Using unityVersion from repo var: $resolved"
      echo "unityVersion=$resolved" >> "$GITHUB_OUTPUT"
      exit 0
    else
      echo "⚠️ Repo var unityVersion invalid: $UNITY_VERSION_REPO_VAR"
    fi
  fi

  # ─────────────────────────────────────────────────────────────
  # Step 3: Check project defaults.json
  # ─────────────────────────────────────────────────────────────
  if [[ -n "$PROJECT_DEFAULT_UNITY" ]]; then
    if resolved=$(validate_unity_version "$PROJECT_DEFAULT_UNITY"); then
      echo "✅ Using unityVersion from project config: $resolved"
      echo "unityVersion=$resolved" >> "$GITHUB_OUTPUT"
      exit 0
    else
      echo "⚠️ Project config unityVersion invalid: $PROJECT_DEFAULT_UNITY"
    fi
  fi

  # ─────────────────────────────────────────────────────────────
  # Step 4: Check action fallback defaults.json
  # ─────────────────────────────────────────────────────────────
  if [[ -n "$ACTION_DEFAULT_UNITY" ]]; then
    if resolved=$(validate_unity_version "$ACTION_DEFAULT_UNITY"); then
      echo "✅ Using unityVersion from action fallback: $resolved"
      echo "unityVersion=$resolved" >> "$GITHUB_OUTPUT"
      exit 0
    else
      echo "❌ Action fallback unityVersion invalid: $ACTION_DEFAULT_UNITY"
      exit 1
    fi
  fi

  # ─────────────────────────────────────────────────────────────
  # Fail if none resolved
  # ─────────────────────────────────────────────────────────────
  echo "❌ No valid unityVersion could be resolved."
  exit 1
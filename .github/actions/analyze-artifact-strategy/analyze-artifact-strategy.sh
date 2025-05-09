#!/bin/bash
set -e

DEPLOY_TARGETS="$1"
ARTIFACT_SOURCE="$2"
CONFIG_FILE=".github/config/deploy-targets.json"
FALLBACK_URL="https://raw.githubusercontent.com/avalin/unity-ci-templates/main/.github/config/deploy-targets.json"

# ────────────────────────────────────────────────
echo "🔍 Loading deploy-targets.json..."

if [ -f "$CONFIG_FILE" ]; then
  echo "✅ Found config at $CONFIG_FILE"
else
  echo "⚠️ Config not found. Fetching from fallback..."
  mkdir -p "$(dirname "$CONFIG_FILE")"
  curl -sSL "$FALLBACK_URL" -o "$CONFIG_FILE" || {
    echo "❌ Failed to download config. Defaulting outputs to false."
    echo "requiresCombined=false" >> "$GITHUB_OUTPUT"
    echo "skipPerBuildTarget=false" >> "$GITHUB_OUTPUT"
    exit 0
  }
fi

# ────────────────────────────────────────────────
echo "🔍 Analyzing deploy targets..."

requires_combined=false
all_require_combined=true
any_target=false

for t in $(echo "$DEPLOY_TARGETS" | jq -r '.[]'); do
  any_target=true
  required=$(jq -r --arg t "$t" '.[$t].requiresCombinedArtifact // false' "$CONFIG_FILE")
  if [[ "$required" == "true" ]]; then
    echo "🔹 $t requires combined artifact."
    requires_combined=true
  else
    echo "✔️ $t does not require combined artifact."
    all_require_combined=false
  fi
done

# ────────────────────────────────────────────────
echo "requiresCombined=$requires_combined" >> "$GITHUB_OUTPUT"

if [[ "$any_target" == "true" && "$all_require_combined" == "true" && "$ARTIFACT_SOURCE" == "release" ]]; then
  echo "🔹 All deploy targets require combined artifacts and pull from release."
  echo "skipPerBuildTarget=true" >> "$GITHUB_OUTPUT"
else
  echo "skipPerBuildTarget=false" >> "$GITHUB_OUTPUT"
fi

# Optional visual output
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚖️ Artifact Strategy Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deploy Targets: $DEPLOY_TARGETS"
echo "Artifact Source: $ARTIFACT_SOURCE"
echo "requiresCombined: $requires_combined"
echo "skipPerBuildTarget: $([ "$all_require_combined" == "true" ] && [ "$ARTIFACT_SOURCE" == "release" ] && echo true || echo false)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
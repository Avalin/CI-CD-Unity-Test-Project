#!/bin/bash
set -e

RAW_INPUT="$1"
BUILD_TYPE="$2"
BUILD_TARGETS_RAW="$3"
CONFIG_FILE=".github/config/deploy-targets.json"
FALLBACK_URL="https://raw.githubusercontent.com/avalin/unity-ci-templates/main/.github/config/deploy-targets.json"

# ─────────────────────────────────────────────────────────────
# Step 1: Validate JSON input
echo "🔍 Raw deployTargets input: $RAW_INPUT"
if ! echo "$RAW_INPUT" | jq empty 2>/dev/null; then
  echo "❌ Invalid JSON in deployTargets input!"
  echo "validDeployTargets=[]" >> "$GITHUB_OUTPUT"
  echo "skipAnalysis=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

if [ "$(echo "$RAW_INPUT" | jq 'length')" -eq 0 ]; then
  echo "ℹ️ No deploy targets provided (empty array). Skipping validation."
  echo "validDeployTargets=[]" >> "$GITHUB_OUTPUT"
  echo "skipAnalysis=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "✅ Input is non-empty and valid JSON."
echo "skipAnalysis=false" >> "$GITHUB_OUTPUT"

# ─────────────────────────────────────────────────────────────
# Step 2: Load config
if [ -f "$CONFIG_FILE" ]; then
  echo "✅ Found local config file: $CONFIG_FILE"
else
  echo "⚠️ Not found. Downloading from: $FALLBACK_URL"
  mkdir -p "$(dirname "$CONFIG_FILE")"
  curl -sSL "$FALLBACK_URL" -o "$CONFIG_FILE"
fi

# ─────────────────────────────────────────────────────────────
# Step 3: Parse ranks
case "$BUILD_TYPE" in
  preview) BUILD_RANK=1 ;;
  release_candidate) BUILD_RANK=2 ;;
  release) BUILD_RANK=3 ;;
  *) echo "❌ Unknown build type: $BUILD_TYPE"; exit 1 ;;
esac

BUILD_TARGETS=$(echo "$BUILD_TARGETS_RAW" | jq -r '.[]')
VALID=()
INVALID=()
SKIPPED_MINIMUM=()
SKIPPED_NO_BUILD_TARGETS=()

for TARGET in $(echo "$RAW_INPUT" | jq -r '.[]'); do
  if jq -e --arg key "$TARGET" '.[$key]' "$CONFIG_FILE" >/dev/null; then
    MIN_TYPE=$(jq -r --arg key "$TARGET" '.[$key].minimumBuildType' "$CONFIG_FILE")
    COMPATIBLE_BUILD_TARGETS=$(jq -r --arg key "$TARGET" '.[$key].compatibleBuildTargets[]' "$CONFIG_FILE")

    case "$MIN_TYPE" in
      preview) MIN_RANK=1 ;;
      release_candidate) MIN_RANK=2 ;;
      release) MIN_RANK=3 ;;
      *) echo "❌ Unknown minimumBuildType for $TARGET: $MIN_TYPE"; exit 1 ;;
    esac

    if [ "$BUILD_RANK" -lt "$MIN_RANK" ]; then
      SKIPPED_MINIMUM+=("$TARGET (requires $MIN_TYPE)")
      continue
    fi

    MATCH=false
    for bt in $BUILD_TARGETS; do
      if echo "$COMPATIBLE_BUILD_TARGETS" | grep -q "^$bt$"; then
        MATCH=true
        break
      fi
    done

    if [ "$MATCH" = true ]; then
      VALID+=("$TARGET")
    else
      SKIPPED_NO_BUILD_TARGETS+=("$TARGET")
    fi
  else
    INVALID+=("$TARGET")
  fi
done

# ─────────────────────────────────────────────────────────────
# Step 4: Output validated targets
if [ "${#VALID[@]}" -eq 0 ]; then
  json='[]'
else
  json=$(printf '%s\n' "${VALID[@]}" | jq -R . | jq -s .)
fi

echo "validDeployTargets<<EOF" >> "$GITHUB_OUTPUT"
echo "$json" >> "$GITHUB_OUTPUT"
echo "EOF" >> "$GITHUB_OUTPUT"

# ─────────────────────────────────────────────────────────────
# Step 5: Print summary
echo ""
echo "📋 Deploy Target Validation Summary"
echo "────────────────────────────────────"
if [ "${#VALID[@]}" -gt 0 ]; then
  echo "✅ Final Valid Targets:"
  for v in "${VALID[@]}"; do echo "  - $v"; done
else
  echo "ℹ️ No valid deploy targets remaining after validation."
fi

if [ "${#INVALID[@]}" -gt 0 ]; then
  echo ""
  echo "⚠️ Invalid (Unknown) Targets:"
  for i in "${INVALID[@]}"; do echo "  - $i"; done
fi

if [ "${#SKIPPED_MINIMUM[@]}" -gt 0 ]; then
  echo ""
  echo "⚠️ Skipped (Minimum BuildType Not Met):"
  for s in "${SKIPPED_MINIMUM[@]}"; do echo "  - $s"; done
fi

if [ "${#SKIPPED_NO_BUILD_TARGETS[@]}" -gt 0 ]; then
  echo ""
  echo "⚠️ Skipped (No Compatible Build Targets):"
  for s in "${SKIPPED_NO_BUILD_TARGETS[@]}"; do echo "  - $s"; done
fi
echo "────────────────────────────────────"
#!/bin/bash
set -euo pipefail

DEST_DIR="${1:?Missing artifact destination directory}"
PROJECT_NAME="${2:?Missing project name}"
VERSION="${3:?Missing version}"
BUILD_TARGETS_JSON="${4:?Missing build targets JSON}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Starting Build Artifact Download"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Project Name             : ${PROJECT_NAME}"
echo "🔹 Version                  : ${VERSION}"
echo "🔹 Destination Directory    : ${DEST_DIR}"
echo "🔹 Build Targets (JSON)     : $(echo "$BUILD_TARGETS_JSON" | jq -r '.[]' | tr '\n' ' ')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -z "${GH_TOKEN:-}" ]; then
  echo "❌ GH_TOKEN environment variable not set. Cannot use gh CLI."
  exit 1
fi

mkdir -p "${DEST_DIR}"

# Convert the JSON string into a valid array
BUILD_TARGETS=$(echo "$BUILD_TARGETS_JSON" | jq -r '.[]')

# ────────────────────────────
# Download Per Platform
# ────────────────────────────
for buildTarget in $BUILD_TARGETS; do
  ARTIFACT_NAME="${PROJECT_NAME}-${VERSION}-${buildTarget}"
  BUILD_TARGET_DIR="${DEST_DIR}/${buildTarget}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⬇️  Downloading Artifact"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔸 Build Target    : ${buildTarget}"
  echo "🔸 Artifact Name   : ${ARTIFACT_NAME}"
  echo "🔸 Target Folder   : ${BUILD_TARGET_DIR}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  mkdir -p "${BUILD_TARGET_DIR}"

  if gh run download --name "${ARTIFACT_NAME}" --dir "${BUILD_TARGET_DIR}"; then
    echo "✅ Successfully downloaded: ${ARTIFACT_NAME}"
  else
    echo "⚠️ Warning: Artifact ${ARTIFACT_NAME} not found or failed to download."
  fi
done

echo ""
echo "✅ All required platform artifacts downloaded into: ${DEST_DIR}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
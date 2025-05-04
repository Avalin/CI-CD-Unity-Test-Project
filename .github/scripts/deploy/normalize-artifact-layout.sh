#!/bin/bash
set -euo pipefail

DEPLOY_DIR="${1:?Missing deployment directory}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛠️ Starting Artifact Layout Normalization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Source Directory: ${DEPLOY_DIR}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for artifact_dir in "${DEPLOY_DIR}"/*; do
  [[ -d "$artifact_dir" ]] || continue
  base_name="$(basename "$artifact_dir")"

  # Extract platform part after last hyphen
  platform_name="${base_name##*-}"
  target_dir="${DEPLOY_DIR}/${platform_name}"

  echo "➡️ Renaming '${artifact_dir}' → '${target_dir}'"
  mv "$artifact_dir" "$target_dir"
done

echo "✅ Artifact layout normalized."
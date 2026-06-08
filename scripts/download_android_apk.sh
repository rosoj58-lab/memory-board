#!/usr/bin/env bash
set -euo pipefail

artifact_name="memory-board-debug-apk"
run_id="${1:-}"
output_dir="${2:-artifacts/${artifact_name}}"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required: gh"
  exit 1
fi

if [[ -z "${run_id}" ]]; then
  run_id="$(
    gh run list \
      --workflow Android \
      --branch main \
      --status success \
      --limit 1 \
      --json databaseId \
      --jq '.[0].databaseId'
  )"
fi

if [[ -z "${run_id}" || "${run_id}" == "null" ]]; then
  echo "No successful Android workflow run was found on main."
  exit 1
fi

rm -rf "${output_dir}"
mkdir -p "${output_dir}"

gh run download "${run_id}" --name "${artifact_name}" --dir "${output_dir}"

apk_path="${output_dir}/app-debug.apk"
if [[ ! -f "${apk_path}" ]]; then
  echo "APK artifact downloaded, but ${apk_path} was not found."
  exit 1
fi

echo "Downloaded ${apk_path}"

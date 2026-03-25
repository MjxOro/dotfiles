#!/usr/bin/env bash
set -euo pipefail

sources_file="autoresearch.sources.txt"

if [[ ! -f "$sources_file" ]]; then
  echo "METRIC primary_sources=0"
  echo "METRIC official_sources=0"
  echo "METRIC fresh_sources_90d=0"
  echo "METRIC plugin_signals=0"
  echo "METRIC omp_patch_surface=0"
  exit 0
fi

primary_sources=$(grep -Evc '^[[:space:]]*(#|$)' "$sources_file" || true)
official_sources=$(grep -Eic 'github\.com|npmjs\.com|bun\.sh|x\.com|twitter\.com' "$sources_file" || true)
fresh_sources_90d=$(grep -Eic '#fresh' "$sources_file" || true)
plugin_signals=$(grep -Eic 'plugin|design-deck|multi-pass|autoresearch' "$sources_file" || true)
omp_patch_surface=$(grep -Eic 'patch|compat|namespace|@mariozechner|@oh-my-pi' "$sources_file" || true)

echo "METRIC primary_sources=${primary_sources}"
echo "METRIC official_sources=${official_sources}"
echo "METRIC fresh_sources_90d=${fresh_sources_90d}"
echo "METRIC plugin_signals=${plugin_signals}"
echo "METRIC omp_patch_surface=${omp_patch_surface}"

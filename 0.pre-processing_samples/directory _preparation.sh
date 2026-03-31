#!/bin/bash
set -euo pipefail


BASE_DIR="$(pwd)}"

# Órganos a crear
ORGANS=(
  brain
  d_intestine
  gill
  gonad
  kidney
  liver
  muscle
)


mkdir -p "$BASE_DIR/ref"


for organ in "${ORGANS[@]}"; do
  mkdir -p "$BASE_DIR/$organ/CESGA"
  mkdir -p "$BASE_DIR/$organ/raw_reads"
  mkdir -p "$BASE_DIR/$organ/reads_per_gen"
  mkdir -p "$BASE_DIR/$organ/scripts"
done


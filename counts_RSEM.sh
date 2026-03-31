#!/bin/bash
#SBATCH -J rsem-T
#SBATCH -o rsem_%j.out
#SBATCH --cpus-per-task=8
#SBATCH --mem=10G
#SBATCH -t 08:00:00


set -euo pipefail
shopt -s nullglob


module load cesga/2020 gcc/system rsem/1.3.1

BASE_DIR="$(pwd)"
STAR_DIR="$BASE_DIR/star_results"
RESULTS_DIR="$BASE_DIR/rsem_results"

REF_DIR="$BASE_DIR/../ref"
GTF="$REF_DIR/........gtf"
FASTA="$REF_DIR/.......fa"

RSEM_DIR="$REF_DIR/rsem_reference"
RSEM_REF="$RSEM_DIR/rsem_ref"

mkdir -p "$RESULTS_DIR"
mkdir -p "$RSEM_DIR"

if [[ ! -f "${RSEM_REF}.grp" ]]; then
    rsem-prepare-reference \
      --gtf "$GTF" \
      "$FASTA" \
      "$RSEM_REF"
fi

for SAMPLE_DIR in "$STAR_DIR"/*; do
    SAMPLE=$(basename "$SAMPLE_DIR")
    BAM="$SAMPLE_DIR/Aligned.toTranscriptome.out.bam"
    OUT_PREFIX="$RESULTS_DIR/$SAMPLE"

    if [[ ! -f "$BAM" ]]; then
        echo "Falta Aligned.toTranscriptome.out.bam en: $SAMPLE"
        continue
    fi

    rsem-calculate-expression \
      --paired-end \
      --bam \
      --no-bam-output \
      --strandedness reverse \
      -p "$SLURM_CPUS_PER_TASK" \
      "$BAM" \
      "$RSEM_REF" \
      "$OUT_PREFIX"
done
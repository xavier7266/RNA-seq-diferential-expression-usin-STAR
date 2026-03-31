#!/bin/bash
#SBATCH -J star_align
#SBATCH --cpus-per-task=8
#SBATCH --mem=35G
#SBATCH -o star_aligment_%j.out
#SBATCH -t 24:00:00


set -euo pipefail
shopt -s nullglob

module load cesga/2020
module load star


BASE_DIR="$(pwd)"
CLEAN_DIR="$BASE_DIR/clean_reads"
RESULTS_DIR="$BASE_DIR/star_results"

##############  modificarlo a el directorio donde esta el indexado creado por star_index.sh

INDEX_DIR="$BASE_DIR/../star_index/"

##############


mkdir -p "$RESULTS_DIR"

for R1 in "$CLEAN_DIR"/*_1_clean.fastq.gz; do
    SAMPLE=$(basename "$R1" _1_clean.fastq.gz)
    R2="$CLEAN_DIR/${SAMPLE}_2_clean.fastq.gz"
    OUTDIR="$RESULTS_DIR/$SAMPLE"

    if [[ ! -f "$R2" ]]; then
        echo "Falta el archivo R2 para la muestra: $SAMPLE"
        continue
    fi

    mkdir -p "$OUTDIR"

    STAR \
      --runThreadN "$SLURM_CPUS_PER_TASK" \
      --genomeDir "$INDEX_DIR" \
      --readFilesIn "$R1" "$R2" \
      --readFilesCommand zcat \
      --outFileNamePrefix "$OUTDIR/" \
      --outSAMtype BAM SortedByCoordinate \
      --outFilterMultimapNmax 1 \
      --quantMode TranscriptomeSAM GeneCounts

    
done

#!/bin/bash
#SBATCH -J star_index
#SBATCH -o star_index_%j.out
#SBATCH -e star_index_%j.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=80G
#SBATCH -t 24:00:00

set -euo pipefail

module load cesga/2020
module load star

BASE_DIR="$(pwd)"
INDEX_DIR="$BASE_DIR/star_index"

# Rutas de referencia
REF_FASTA="$BASE_DIR/ref/.....fa"
REF_GTF="$BASE_DIR/ref/.....gtf"

# Tomar en cuenta el tamaño de las lecturas
SJDB_OVERHANG=149

mkdir -p "$INDEX_DIR"

STAR \
  --runThreadN "$SLURM_CPUS_PER_TASK" \
  --runMode genomeGenerate \
  --genomeDir "$INDEX_DIR" \
  --genomeFastaFiles "$REF_FASTA" \
  --sjdbGTFfile "$REF_GTF" \
  --sjdbOverhang "$SJDB_OVERHANG"




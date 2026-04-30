#!/bin/bash
#SBATCH -J fastp
#SBATCH -o fastp_%j.out
#SBATCH -e fastp_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH -t 03:00:00

set -euo pipefail
shopt -s nullglob

module load fastp

BASE_DIR="$(pwd)"
RAW_DIR="$BASE_DIR/raw_reads"
CLEAN_DIR="clean_reads"
REPORT_DIR="reportes_fastp"

mkdir -p "$CLEAN_DIR" "$REPORT_DIR"

archivos_r1=( "$RAW_DIR"/*_1.fastq.gz )

if [ ${#archivos_r1[@]} -eq 0 ]; then
    echo "No se encontraron archivos *_1.fastq.gz en $RAW_DIR"
    exit 1
fi

for r1 in "${archivos_r1[@]}"; do
    nombre_base=$(basename "$r1" _1.fastq.gz)
    r2="$RAW_DIR/${nombre_base}_2.fastq.gz"

    if [ ! -f "$r2" ]; then
        echo "Falta el archivo pareja para $nombre_base"
        continue
    fi

    echo "Procesando muestra: $nombre_base"

    fastp \
      -i "$r1" \
      -I "$r2" \
      -o "$CLEAN_DIR/${nombre_base}_1_clean.fastq.gz" \
      -O "$CLEAN_DIR/${nombre_base}_2_clean.fastq.gz" \
      -h "$REPORT_DIR/${nombre_base}_report.html" \
      -j "$REPORT_DIR/${nombre_base}_report.json" \
      -w "$SLURM_CPUS_PER_TASK"
done
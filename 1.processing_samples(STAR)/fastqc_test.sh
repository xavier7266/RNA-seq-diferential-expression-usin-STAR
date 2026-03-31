#!/bin/bash

module load FastQC

OUTDIR="fastqc_results"
THREADS="${SLURM_CPUS_PER_TASK:-4}"

mkdir -p "$OUTDIR"

files=( *.gz )

if [[ ${#files[@]} -eq 0 ]]; then
    echo "No se encontraron archivos .gz en $(pwd)" >&2
    exit 1
fi

fastqc -t "$THREADS" -o "$OUTDIR" "${files[@]}"
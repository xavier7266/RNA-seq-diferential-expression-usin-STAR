#!/bin/bash
#SBATCH -J merge_rsem_global
#SBATCH -o merge_rsem_global_%j.out
#SBATCH -c 1
#SBATCH -t 01:00:00
#SBATCH --mem=1G

set -euo pipefail


# 1) RUTA BASE Y SALIDA

BASE_DIR="$(pwd)" 
# Recomendacion, el script esta diseñado para ejecutarse dentro de la carpeta "organismo" donde estan todas las subcarpetas de organos.
#Si se ejecuta desde otro lugar, ajustar esta ruta a la carpeta que contiene las subcarpetas de organos.

OUT_DIR="$BASE_DIR/rsem_global_matrix"

mkdir -p "$OUT_DIR"

COUNTS_OUT="$OUT_DIR/rsem_gene_expected_count_matrix.tsv"
TPM_OUT="$OUT_DIR/rsem_gene_tpm_matrix.tsv"



# 2) ÓRGANOS A RECORRER


ORGANS=(brain d_intestine gill gonad kidney liver muscle)


# 3) REUNIR TODOS LOS .genes.results

FILES=()

for organ in "${ORGANS[@]}"; do
    RSEM_DIR="$BASE_DIR/$organ/rsem_results"

    if [ -d "$RSEM_DIR" ]; then
        for f in "$RSEM_DIR"/*.genes.results; do
            [ -e "$f" ] || continue
            FILES+=( "$f" )
        done
    fi
done

if [ "${#FILES[@]}" -eq 0 ]; then
    echo "No se encontraron archivos .genes.results"
    exit 1
fi


# 4) USAR EL PRIMER ARCHIVO COMO REFERENCIA PARA LOS IDS DE LOS GENES Y CREAR LAS PRIMERAS COLUMNAS DE LOS ARCHIVOS DE SALIDA


FIRST_FILE="${FILES[0]}"

awk 'NR>1 {print $1}' "$FIRST_FILE" > "$OUT_DIR/gene_ids.tmp"

cp "$OUT_DIR/gene_ids.tmp" "$OUT_DIR/counts_body.tmp"
cp "$OUT_DIR/gene_ids.tmp" "$OUT_DIR/tpm_body.tmp"

echo "gene_id" > "$OUT_DIR/counts_header.tmp"
echo "gene_id" > "$OUT_DIR/tpm_header.tmp"

: > "$OUT_DIR/counts_samples.tmp"
: > "$OUT_DIR/tpm_samples.tmp"


# 5) RECORRER CADA ARCHIVO Y EXTRAER CUENTAS Y TPMs, CONSTRUIR MATRICES DE CUENTAS Y TPMs

for f in "${FILES[@]}"; do
    sample=$(basename "$f" .genes.results)
    organ=$(basename "$(dirname "$(dirname "$f")")")
    sample_name="${organ}_${sample}"

    echo "Procesando $sample_name"

    echo "$sample_name" >> "$OUT_DIR/counts_samples.tmp"
    echo "$sample_name" >> "$OUT_DIR/tpm_samples.tmp"

    awk 'NR>1 {print $5}' "$f" > "$OUT_DIR/${sample_name}_counts.tmp"
    awk 'NR>1 {print $6}' "$f" > "$OUT_DIR/${sample_name}_tpm.tmp"

    paste "$OUT_DIR/counts_body.tmp" "$OUT_DIR/${sample_name}_counts.tmp" > "$OUT_DIR/counts_new.tmp"
    mv "$OUT_DIR/counts_new.tmp" "$OUT_DIR/counts_body.tmp"

    paste "$OUT_DIR/tpm_body.tmp" "$OUT_DIR/${sample_name}_tpm.tmp" > "$OUT_DIR/tpm_new.tmp"
    mv "$OUT_DIR/tpm_new.tmp" "$OUT_DIR/tpm_body.tmp"
done


# 6) CREAR CABECERAS FINALES

COUNTS_HEADER_LINE="gene_id"
while read -r s; do
    COUNTS_HEADER_LINE="${COUNTS_HEADER_LINE}\t${s}"
done < "$OUT_DIR/counts_samples.tmp"

TPM_HEADER_LINE="gene_id"
while read -r s; do
    TPM_HEADER_LINE="${TPM_HEADER_LINE}\t${s}"
done < "$OUT_DIR/tpm_samples.tmp"

echo -e "$COUNTS_HEADER_LINE" > "$COUNTS_OUT"
cat "$OUT_DIR/counts_body.tmp" >> "$COUNTS_OUT"

echo -e "$TPM_HEADER_LINE" > "$TPM_OUT"
cat "$OUT_DIR/tpm_body.tmp" >> "$TPM_OUT"

# ELIMINAR ARCHIVOS TEMPORALES

rm -f "$OUT_DIR"/*.tmp


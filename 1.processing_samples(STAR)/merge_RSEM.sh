#!/bin/bash
#SBATCH -J merge-rsem
#SBATCH -o merge-rsem-%j.out
#SBATCH -e merge-rsem-%j.err
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH -t 01:00:00


set -euo pipefail

# RUTAS DEL DIRECTORIO DE RESULTADOS DE RSEM Y DEL DIRECTORIO DE SALIDA

BASE_DIR="$(pwd)"
RSEM_DIR="${BASE_DIR}/rsem_results"
OUT_DIR="${BASE_DIR}/merged_rsem_results"
mkdir -p "${OUT_DIR}"
COUNTS_OUT="${OUT_DIR}/rsem_gene_expected_count_matrix.tsv"
TPM_OUT="${OUT_DIR}/rsem_gene_tpm_matrix.tsv"

#ARCHIVOS DE RESULTADOS DE RSEM

FILES=("${RSEM_DIR}"/*.genes.results)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No RSEM result files found in ${RSEM_DIR}"
    exit 1
fi

# CREAR PRIMERA COLUMNA DE LOS ARCHIVOS DE SALIDA CON LOS IDS DE LOS GENES

FIRST_FILE="${FILES[0]}"
awk 'NR>1 {print $1}' "${FIRST_FILE}" > "${OUT_DIR}/gene_ids.tmp"

# INICIALIZAR MATRICES DE CUENTAS

cp "${OUT_DIR}/gene_ids.tmp" "${OUT_DIR}/counts_body.tmp"
cp "${OUT_DIR}/gene_ids.tmp" "${OUT_DIR}/tpm_body.tmp"

echo -e "gene_id" > "${OUT_DIR}/counts_header.tmp"
echo -e "gene_id" > "${OUT_DIR}/tpm_header.tmp"

for f in "${FILES[@]}"; do
    SAMPLE_NAME=$(basename "${f}" .genes.results)
    echo "Processing ${SAMPLE_NAME} from ${f}"
    
    echo -e "\t${SAMPLE_NAME}" >> "${OUT_DIR}/counts_sample.tmp"
    echo -e "\t${SAMPLE_NAME}" >> "${OUT_DIR}/tpm_sample.tmp"

    awk 'NR>1 {print $5}' "${f}" > "${OUT_DIR}/${SAMPLE_NAME}_counts.tmp"   
    awk 'NR>1 {print $6}' "${f}" > "${OUT_DIR}/${SAMPLE_NAME}_tpm.tmp"
    paste "${OUT_DIR}/counts_body.tmp" "${OUT_DIR}/${SAMPLE_NAME}_counts.tmp" > "${OUT_DIR}/counts_body.tmp"
    mv "${OUT_DIR}/counts_body.tmp" "${OUT_DIR}/counts_body.tmp"
    paste "${OUT_DIR}/tpm_body.tmp" "${OUT_DIR}/${SAMPLE_NAME}_tpm.tmp" > "${OUT_DIR}/tpm_body.tmp"
    mv "${OUT_DIR}/tpm_body.tmp" "${OUT_DIR}/tpm_body.tmp"
done
paste "${OUT_DIR}/counts_header.tmp" "${OUT_DIR}/counts_sample.tmp" > "${COUNTS_OUT/counts_header_final.tmp}"
paste "${OUT_DIR}/tpm_header.tmp" "${OUT_DIR}/tpm_sample.tmp" > "${OUT_DIR/tpm_header_final.tmp}"

tr '\t' '\n' < /dev/null > /dev/null 2>/dev/null || true

COUNTS_HEADER=$(paste -sd $'\t' "${OUT_DIR}/counts_header_final.tmp")
TPM_HEADER=$(paste -sd $'\t' "${OUT_DIR}/tpm_header_final.tmp}")

echo -e "${COUNTS_HEADER}" > "${COUNTS_OUT}"
cat "${OUT_DIR}/counts_body.tmp" >> "${COUNTS_OUT}"

echo -e "${TPM_HEADER}" > "${TPM_OUT}"
cat "${OUT_DIR}/tpm_body.tmp" >> "${TPM_OUT}"

rm -f "OUT_DIR"/*.tmp


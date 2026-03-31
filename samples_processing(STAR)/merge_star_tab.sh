#!/bin/bash
set -euo pipefail
shopt -s nullglob

BASE_DIR="$(pwd)"
STAR_DIR="$BASE_DIR/star_results"
OUTFILE="$BASE_DIR/star_counts_matrix_annotated.tsv"

# Cambia esta ruta por tu GTF
GTF="$BASE_DIR/../ref/....gtf"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

files=("$STAR_DIR"/*/ReadsPerGene.out.tab)
[[ ${#files[@]} -gt 0 ]] || {
    echo "Error: no se encontraron archivos ReadsPerGene.out.tab en $STAR_DIR" >&2
    exit 1
}

first=1

for f in "${files[@]}"; do
    sample=$(basename "$(dirname "$f")")
    awk 'BEGIN{OFS="\t"} NR>4 {print $1, $2}' "$f" > "$TMPDIR/${sample}.tsv"

    if [[ $first -eq 1 ]]; then
        cut -f1 "$TMPDIR/${sample}.tsv" > "$TMPDIR/genes.tsv"
        first=0
    fi
done

for f in "$TMPDIR"/*.tsv; do
    base=$(basename "$f")
    [[ "$base" == "genes.tsv" ]] && continue

    sample="${base%.tsv}"
    cut -f2 "$f" > "$TMPDIR/${sample}_counts.tsv"
done

{
    printf "gene_id\tgene_name"
    for f in "$TMPDIR"/*_counts.tsv; do
        sample=$(basename "$f" _counts.tsv)
        printf "\t%s" "$sample"
    done
    printf "\n"
} > "$OUTFILE"

awk '
BEGIN{OFS="\t"}
$3=="gene" {
    gene_id=""
    gene_name=""
    if (match($0, /gene_id "([^"]+)"/, a)) gene_id=a[1]
    if (match($0, /gene_name "([^"]+)"/, b)) gene_name=b[1]
    if (gene_id != "" && gene_name != "") print gene_id, gene_name
}
' "$GTF" | sort -u > "$TMPDIR/gene_annotation.tsv"

paste "$TMPDIR/genes.tsv" "$TMPDIR"/*_counts.tsv > "$TMPDIR/raw_matrix.tsv"

awk 'BEGIN{FS=OFS="\t"}
NR==FNR {
    annot[$1]=$2
    next
}
{
    print $1, ($1 in annot ? annot[$1] : "NA"), substr($0, index($0,$2))
}
' "$TMPDIR/gene_annotation.tsv" "$TMPDIR/raw_matrix.tsv" >> "$OUTFILE"
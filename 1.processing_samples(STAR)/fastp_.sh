#!/bin/bash         
#SBATCH -o fastp_%j.out           
#SBATCH -e fastp_%j.err           
#SBATCH --cpus-per-task=4         
#SBATCH --mem=4G                  
#SBATCH -t 04:00:00               
#SBATCH --mail-type=END,FAIL      

set -uo pipefail
module load fastp

#Este script debe ejecutarse en la carpeta con los archivos .fastq.gz que se vayan a analizar con fastp.


#Generara 2 carpetas para guardar reads limpias y organizar
mkdir -p reads_limpios reportes_fastp

#Ejecuta en bucle todos los archivos ".fastq.gz" con el programa fastp y carga los archivos limpios en la carpeta "reads limpios".

for archivo in *.fastq.gz; do
    nombre_base=$(basename "$archivo" .fastq.gz)
    
    fastp -i "$archivo" \
          -o "reads_limpios/${nombre_base}_clean.fastq.gz" \
          -h "reportes_fastp/${nombre_base}_report.html" \
          -w $SLURM_CPUS_PER_TASK
done
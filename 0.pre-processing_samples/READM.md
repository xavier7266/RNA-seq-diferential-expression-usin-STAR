# Organización de carpetas para análisis transcriptómico en CESGA

Este proyecto utiliza una estructura de carpetas homogénea por órgano con el objetivo de facilitar la trazabilidad del análisis, la reutilización de scripts y el mantenimiento ordenado de los resultados en el entorno HPC de CESGA.

## Objetivo de la estructura

La organización se diseñó para separar claramente:

- los **datos de entrada**
- los **scripts**
- los **logs del clúster**
- las **matrices finales de conteo**

De este modo, cada órgano funciona como una unidad de análisis independiente, lo que simplifica la ejecución de pasos como preprocesamiento, alineamiento, cuantificación y fusión posterior de resultados.

## Estructura base

```text
"ESPECIE"/
├── ref/
├── brain/
│   ├── CESGA/
│   ├── raw_reads/
│   ├── reads_per_gen/
│   └── scripts/
├── d_intestine/
│   ├── CESGA/
│   ├── raw_reads/
│   ├── reads_per_gen/
│   └── scripts/
├── gill/
│   ├── CESGA/
│   ├── raw_reads/
│   ├── reads_per_gen/
│   └── scripts/
├── gonad/
│   ├── CESGA/
│   ├── raw_reads/
│   ├── reads_per_gen/
│   └── scripts/
├── kidney/
│   ├── CESGA/
│   ├── raw_reads/
│   ├── reads_per_gen/
│   └── scripts/
├── liver/
│   ├── CESGA/
│   ├── raw_reads/
│   ├── reads_per_gen/
│   └── scripts/
└── muscle/
    ├── CESGA/
    ├── raw_reads/
    ├── reads_per_gen/
    └── scripts/

```

### Descripción de carpetas

- **raw_reads/**  
  Contiene las lecturas crudas originales (FASTQ).  
  No se modifican y sirven como respaldo inicial del análisis.

- **scripts/**  
  Scripts utilizados en cada etapa del pipeline (fastp, STAR, RSEM, etc.).  
  Permiten automatizar y reproducir el análisis.

- **CESGA/**  
  Archivos de salida (`.out`) y error (`.err`) generados por SLURM.  
  Se utilizan para depuración y seguimiento de ejecuciones.

- **reads_per_gen/**  
  Matrices finales de conteo por gen (STAR, RSEM, etc.).  
  Son la entrada directa para análisis en R (DESeq2).

### Carpetas generadas automáticamente

Durante la ejecución del pipeline se crean otras carpetas, como:

- `clean_reads/` → lecturas filtradas (fastp)  
- `reportes_fastp/` → informes de calidad  
- `star_results/` → archivos de alineamiento  
- `rsem_results/` → resultados de cuantificación  

Estas no se incluyen en la estructura base porque son generadas automáticamente por las herramientas.

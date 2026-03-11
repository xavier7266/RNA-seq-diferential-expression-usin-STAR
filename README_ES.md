# Inicio de Analisis transcriptomicos.

Para obtener los datos transcriptómicos iniciales, se procedió a buscarlos en la base de datos de SalmoBase, concretamente en el conjunto de datos AQUA-FAANG, donde se encuentra compartida la información del proyecto AQUA-FAANG.

Se revisaron los datos del Bodymap de trucha arcoiris (*Oncorhynchus mykiss*) y de salmon atlantico (*Salmo salar*). Los bodymaps describían un conjunto de órganos de los cuales se realizó el transcriptoma: cerebro, zona distal del intestino, agallas, gónadas, riñón, hígado y tejido muscular.

La información se organizó en una hoja de cálculo, agrupándola según el interés de la investigación. A partir de estas listas, se descargó desde la propia página el archivo `.sh` con los archivos FASTQ correspondientes a cada órgano.

## Descargar archivos de transcriptomica en CESGA usando SLURM.

```bash
#!/bin/bash

#SBATCH -J download
#SBATCH -o download_%j.out
#SBATCH -e download_%j.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH -t 12:00:00

set -uo pipefail

wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR104/030/ERR104.....
....
....
....
wget -nc ftp://(ftp.sra.ebi.ac.uk/vol1....
```
Este programa descarga todos los archivos solicitados en la carpeta en la que se encuentre. Puede nombrarse de la forma que resulte más cómoda para el usuario y se ejecuta escribiendo en la terminal `sbatch nombre_del_archivo.sh`, estando situado en la carpeta de destino de las descargas y con el archivo `.sh` copiado dentro de dicha carpeta. Un ejemplo del programa esta cargado dentro del repositorio con el nombre de `download_slurm.sh`

## Procesamiento de los datos

Una vez descargados los archivos FASTQ, se realizó un procesamiento inicial de las lecturas con el objetivo de mejorar la calidad de los datos y homogeneizar todas las muestras antes de los análisis posteriores.

Como primera aproximación, se puede utilizar **FastQC** para llevar a cabo una evaluación preliminar de la calidad de las lecturas, lo que permite detectar la presencia de adaptadores, bases de baja calidad o posibles sesgos en la secuenciación. Al ejecutar FastQC en todas tus descargas se van a tener muchos archivos `muestra_fastqc.html`, uno por cada muestra. 

Posteriormente, se aplicó un proceso de *trimming* y filtrado utilizando **fastp**. Esta herramienta permite eliminar adaptadores, recortar regiones de baja calidad y descartar lecturas demasiado cortas o de baja fiabilidad. De este modo, se obtiene un conjunto de secuencias limpias y más adecuadas para las siguientes etapas del análisis transcriptómico.

El uso de **fastp** presenta además la ventaja de integrar, en una sola ejecución, tanto el control de calidad como el filtrado y recorte de lecturas. Al tratarse de una herramienta implementada en C++ y compatible con ejecución multihilo, permite procesar grandes volúmenes de datos de forma rápida y eficiente.

Este paso resulta fundamental para reducir el ruido técnico y asegurar que los análisis posteriores se realicen sobre datos consistentes y comparables entre muestras.

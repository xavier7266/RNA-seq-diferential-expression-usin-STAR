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

## Pre-procesamiento de los datos

Una vez descargados los archivos FASTQ, se realizó un procesamiento inicial de las lecturas con el objetivo de mejorar la calidad de los datos y homogeneizar todas las muestras antes de los análisis posteriores.

Como primera aproximación, se puede utilizar **FastQC** para llevar a cabo una evaluación preliminar de la calidad de las lecturas, lo que permite detectar la presencia de adaptadores, bases de baja calidad o posibles sesgos en la secuenciación. Al ejecutar FastQC en todas tus descargas se van a tener muchos archivos `muestra_fastqc.html`, uno por cada muestra. 

Posteriormente, se aplicó un proceso de *trimming* y filtrado utilizando **fastp**. Esta herramienta permite eliminar adaptadores, recortar regiones de baja calidad y descartar lecturas demasiado cortas o de baja fiabilidad. De este modo, se obtiene un conjunto de secuencias limpias y más adecuadas para las siguientes etapas del análisis transcriptómico. El script `fastp.sh` permite ejecutar en SLURM todos los archivos `fastq.gz` y generar una nueva tanda de archivos limpios en nuevo directorio llamado reads_limpios.

El uso de **fastp** presenta además la ventaja de integrar, en una sola ejecución, tanto el control de calidad como el filtrado y recorte de lecturas. Al tratarse de una herramienta implementada en C++ y compatible con ejecución multihilo, permite procesar grandes volúmenes de datos de forma rápida y eficiente.

Este paso resulta fundamental para reducir el ruido técnico y asegurar que los análisis posteriores se realicen sobre datos consistentes y comparables entre muestras. Si se dispone de poca memoria, se puede añadir una linea de codigo al script `fastp.sh`que elimine los archivos originales con el comando `rm -rf *.fastp.gz` , pero se puede eliminar mas documentos de forma innecesaria si no se tiene cuidado por lo que no se agrego esta funcion en el script adjunto.


# Procesado de secuencias.
Una vez que los datos han sido limpiados y están listos para su análisis, se inicia la etapa de procesamiento. Para ello existen numerosas herramientas y programas bioinformáticos que permiten trabajar con los datos de secuenciación. La elección del software adecuado depende de varios factores, entre ellos el tipo de muestra analizada, la tecnología de secuenciación utilizada, las características de los datos generados y el objetivo final del análisis. Por este motivo, diferentes proyectos o datasets pueden requerir pipelines y herramientas distintas.

## Alineamiento de lecturas con STAR

En este caso se plantea el desarrollo de la *pipeline* utilizando el software **STAR**.  
**STAR (Spliced Transcripts Alignment to a Reference)** es un software bioinformático diseñado para alinear las lecturas obtenidas en una secuenciación contra un genoma de referencia.Este programa utiliza un índice del genoma y un algoritmo denominado MMP (Maximum Mappable Prefix), lo que le permite realizar el alineamiento de grandes volúmenes de datos en tiempos relativamente cortos.

Además, es capaz de identificar las uniones de empalme entre exones (splice junctions) que aparecen en los transcritos. Esta información es clave, ya que permite reconstruir cómo se organizan los transcritos maduros después del proceso de *splicing*.

Para







Como paso previo al conteo de las secuencias, es necesario conocer si estas poseen o no informacion sobre la hebra de origen del RNA, y en base a esta informacion se las describe como unstranded, stranded o reversely stranded. Esto se puede verificar en las librerias al momento de realizar la secuenciacion. Si no se conoce, antes de usar featurecounts se puede ejecutar un conteo repetido en 1 misma muestra en triplicado cambiando la variable -s en el script y viendo los porcentajes de conteos que logra subread. Esto nos permite suponer que tipo de origen tiene el RNA, un script para testear esto es `test_stranded.sh`, se ejecuta en `bash` dentro de la consola y solo se tiene que seleccionar la ubicacion de la misma muestra.


# Obtencion de los datos transcriptomicos.

Para obtener los datos transcriptomicos iniciales, se procedio a buscarlos de la base de datos de Salmobase - AQUA-FAANG dataset donde se encuentran compartidos la base de datos del proyecto AGUA-FAANG.
Se procedio a revisar los datos de Bodymap de Rainbow trout y de Atlantic salmon. Los bodymap describian un conjunto de organos de los cuales se realizo el transcriptoma, cerebro, zona distal del intestino, agallas, gonadas, riñon, higado y tejido muscular. 
Se organizo la informacion en una hoja de calculo, agrupando segun el iteres de la investigacion y con las listas se descargo el archivo .sh de la propia pagina con los archivos fastq de cada organo.
Los archivos para poder ser descargados dentro de CESGA se los preparo de la siguiente manera el encabezado del documento.

""" 
#!/bin/bash

#SBATCH -J download_fastq

#SBATCH -o download_%j.out

#SBATCH -e download_%j.err

#SBATCH --cpus-per-task=1

#SBATCH --mem=2G

#SBATCH -t 12:00:00

set -uo pipefail

wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR104/030/ERR104.....


Ejecutando el archivo se procedio a descargar.


# Trimming de lecturas
Una vez descargado los archivos, se puede ejecutar una serie de scripts para poder analizar los datos descargados. Se puede usar el modulo FastQC para hacer un analisis preliminar de los datos pero al final, es mejor realizar un trimming a todos los archivos para trabajar de forma homogenea, por lo que se puede proceder a ejecutar el programa fastp.
Fastp es una herramienta bioinformática "todo en uno" de altísima velocidad diseñada para el preprocesamiento de datos de secuenciación (archivos FASTQ). Su gran ventaja es que realiza simultáneamente el control de calidad y la limpieza (trimming) de las lecturas en una sola pasada, identificando y eliminando automáticamente secuencias de baja calidad, adaptadores de secuenciación y lecturas que son demasiado cortas para ser útiles. 
Al estar escrito en C++ y soportar ejecución multihilo, hace el trabajo de varios programas clásicos de forma mucho más eficiente, entregando secuencias limpias y reportes visuales detallados listos para la siguiente fase del análisis.

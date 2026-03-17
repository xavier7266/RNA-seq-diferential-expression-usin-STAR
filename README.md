# 🧬 Inicio del análisis transcriptómico

Para la obtención de los datos transcriptómicos iniciales, se accedió a la base de datos **SalmoBase**, concretamente al conjunto de datos **AQUA-FAANG**, donde se encuentra disponible la información asociada a este proyecto.

Se revisaron los *bodymaps* de:
- Trucha arcoíris (*Oncorhynchus mykiss*)
- Salmón atlántico (*Salmo salar*)

Estos *bodymaps* describen un conjunto de órganos a partir de los cuales se obtuvo el transcriptoma:
- Cerebro  
- Intestino distal  
- Agallas  
- Gónadas  
- Riñón  
- Hígado  
- Tejido muscular  

La información se organizó en una hoja de cálculo, agrupando los datos según los objetivos de la investigación. A partir de esta selección, se descargaron desde la propia plataforma los scripts `.sh` que contienen las rutas a los archivos **FASTQ** correspondientes a cada órgano.

## ⬇️ Descarga de archivos de transcriptómica en CESGA usando SLURM

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
Este script descarga todos los archivos solicitados en el directorio en el que se ejecuta. Puede nombrarse de la forma que resulte más conveniente y se lanza desde terminal mediante el comando `sbatch`, aunque tambien se puede usar bash, siempre que el archivo `.sh` se encuentre copiado dentro de la carpeta destino de las descargas. En el repositorio se incluye un ejemplo del script con el nombre de `download_slurm.sh`.

## Preprocesamiento de los datos

Una vez descargados los archivos **FASTQ**, se llevó a cabo un procesamiento inicial de las lecturas con el objetivo de mejorar la calidad de los datos y homogeneizar todas las muestras antes de los análisis posteriores.

Como primera aproximación, puede utilizarse **FastQC** para realizar una evaluación preliminar de la calidad de las lecturas. Esta herramienta permite detectar la presencia de adaptadores, bases de baja calidad y posibles sesgos en la secuenciación. Al ejecutar FastQC sobre todas las muestras descargadas, se generan múltiples archivos de salida en formato `.html`, uno por cada muestra analizada, normalmente con nombres del tipo `muestra_fastqc.html`.

Posteriormente, se aplica un proceso de *trimming* y filtrado mediante **fastp**. Esta herramienta permite eliminar adaptadores, recortar regiones de baja calidad y descartar lecturas demasiado cortas o de baja fiabilidad. De este modo, se obtiene un conjunto de secuencias limpias y más adecuado para las etapas posteriores del análisis transcriptómico. El script `fastp.sh` permite ejecutar este proceso en **SLURM** sobre todos los archivos `fastq.gz`, generando una nueva colección de archivos limpios en un directorio denominado `reads_limpios`.

El uso de **fastp** presenta además la ventaja de integrar, en una sola ejecución, tanto el control de calidad como el filtrado y recorte de lecturas. Al tratarse de una herramienta implementada en **C++** y compatible con ejecución multihilo, permite procesar grandes volúmenes de datos de forma rápida y eficiente.


# Procesado de secuencias.
Una vez que los datos han sido limpiados y están listos para su análisis, se inicia la etapa de procesamiento. Para ello existen numerosas herramientas y programas bioinformáticos que permiten trabajar con los datos de secuenciación. La elección del software adecuado depende de varios factores, entre ellos el tipo de muestra analizada, la tecnología de secuenciación utilizada, las características de los datos generados y el objetivo final del análisis. Por este motivo, diferentes proyectos o datasets pueden requerir pipelines y herramientas distintas.

## Alineamiento de lecturas con STAR

En este caso se plantea el desarrollo de la *pipeline* utilizando el software **STAR**.  
**STAR (Spliced Transcripts Alignment to a Reference)** es un software bioinformático diseñado para alinear las lecturas obtenidas en una secuenciación contra un genoma de referencia.Este programa utiliza un índice del genoma y un algoritmo denominado MMP (Maximum Mappable Prefix), lo que le permite realizar el alineamiento de grandes volúmenes de datos en tiempos relativamente cortos.

Además, es capaz de identificar las uniones de empalme entre exones (splice junctions) que aparecen en los transcritos. Esta información es clave, ya que permite reconstruir cómo se organizan los transcritos maduros después del proceso de *splicing*.

### Descarga de Genoma de referencia y Anotaciones

Para usar STAR, se requiere antes de cargar los datos de secuenciacion, obtener 2 archivos clave:

---
**Genoma de referencia**: Es una secuencia representativa del ADN de una especie que se utiliza como base para alinear las lecturas obtenidas mediante secuenciación. En análisis de RNA-seq, las lecturas generadas por la plataforma de secuenciación se comparan contra este genoma para determinar en qué región del genoma se originan. Esto permite identificar qué genes están siendo expresados y en qué cantidad. El genoma de referencia suele encontrarse en formato **FASTA (.fa o .fasta)**.

Los genomas de referencia pueden obtenerse de diferentes bases de datos públicas dependiendo del organismo de estudio. En estas plataformas es posible buscar el organismo de interés y descargar la versión más reciente del ensamblado del genoma.

- **Ensembl**  
- **NCBI Genome**  
- **UCSC Genome Browser**

---

**Anotaciones genómicas**: Estos archivos contienen la información sobre la localización y estructura de los genes dentro del genoma de referencia. Estas anotaciones indican dónde se encuentran elementos como **genes, exones, intrones, transcritos y otras regiones funcionales**. Durante el análisis de RNA-seq, esta información se utiliza para asignar las lecturas alineadas a genes específicos y poder cuantificar su expresión. Las anotaciones suelen descargarse en formatos estándar como **GTF (Gene Transfer Format)** o **GFF**, que describen las coordenadas de cada elemento genómico dentro del genoma de referencia.

Al igual que el genoma de referencia, las anotaciones deben corresponder a la misma versión del ensamblado por lo que se recomienda que se descarguen de la misma pagina ambos archivos, para evitar inconsistencias durante el análisis. Estas anotaciones también pueden obtenerse de bases de datos similares como:

- **Ensembl**
- **NCBI RefSeq**
- **GENCODE**

---

### Creacion de INDEX del transcriptoma.

Con los archivos descargados, se procede a crear el archivo INDEX ejecuntando STAR, para esto se usa el script `star_index.sh` con el comando:

```bash
#!/bin/bash
#SBATCH --cpus-per-task=8
STAR \
  --runThreadN "$SLURM_CPUS_PER_TASK" \
  --runMode genomeGenerate \
  --genomeDir "$INDEX_DIR" \
  --genomeFastaFiles "$REF_FASTA" \
  --sjdbGTFfile "$REF_GTF" \
  --sjdbOverhang "$SJDB_OVERHANG"
`
```
Donde se puede:
- **$INDEX_DIR**= Directorio donde se guardara el índice el genoma.
- **$REF_FASTA**= Direccion del Genoma de referencia (.fasta / .fa).
- **$REF_GTF**= Direccion de las Anotaciones del genoma (.GTF / .GFF).
- **$SJDB_OVERHANG**= Tamaño de las lecturas (100pb = 99 / 150pb = 149) 

Esto generara un gran numero de archivos entre .txt, .tab, por lo que el script genera un directorio llamado `star_index/`, con todos los archivos. Si se ejecuta desde bash se recomienda ejecutar dentro de un directorio.

### Mapeo de los transcriptos.

Una vez generado el índice del genoma y disponiendo de los archivos de referencia (**.FASTA** y **.GTF**), se puede proceder al alineamiento de las muestras contra el genoma de referencia. Este proceso requiere una cantidad considerable de recursos computacionales, especialmente en términos de CPU y memoria RAM. Por este motivo, el alineamiento se ejecuta mediante `sbatch` en el clúster de **CESGA**, lo que permite gestionar los recursos de forma eficiente y ejecutar la tarea a través del sistema de colas.
Para ello, se desarrolló un script llamado `star_alignment.sh`, encargado de ejecutar el proceso de alineamiento con **STAR** buscando automáticamente todos los archivos de lecturas limpias dentro del sistema de carpetas. El script define variables con las rutas de los directorios, por lo que puede modificarse fácilmente según las necesidades del análisis o la estrucutra de directorios.

Al ejecutar **STAR**, es importante especificar si los datos de secuenciación corresponden a lecturas paired-end o single-end.

Las lecturas paired-end provienen de fragmentos de ADN o ARN que han sido secuenciados desde **ambos extremos del fragmento**, generando dos archivos de lectura por muestra, normalmente denominados R1 y R2. En cambio, las lecturas single-end provienen de la secuenciación de un solo extremo del fragmento, por lo que cada muestra genera un único archivo de lecturas.


```bash
for R1 in "$CLEAN_DIR"/*_1_clean.fastq.gz; do
    SAMPLE=$(basename "$R1" _1_clean.fastq.gz)
    R2="$CLEAN_DIR/${SAMPLE}_2_clean.fastq.gz"
    OUTDIR="$RESULTS_DIR/$SAMPLE"

    if [[ ! -f "$R2" ]]; then
        echo "Falta el archivo R2 para la muestra: $SAMPLE"
        continue
    fi

    mkdir -p "$OUTDIR"

    STAR \
      --runThreadN "$SLURM_CPUS_PER_TASK" \
      --genomeDir "$INDEX_DIR" \
      --readFilesIn "$R1" "$R2" \
      --readFilesCommand zcat \
      --outFileNamePrefix "$OUTDIR/" \
      --outSAMtype BAM SortedByCoordinate \
      --quantMode GeneCounts
   
done
```
La primera parte del script recorre la carpeta de entrada e identifica automáticamente los archivos FASTQ de cada muestra. Los archivos con sufijo `_1.fastq.gz` se asignan como lecturas **R1**, mientras que los archivos con sufijo `_2.fastq.gz` se asignan como lecturas **R2**. El nombre base de cada muestra se guarda en la variable **`$SAMPLE`**, lo que permite emparejar correctamente ambos archivos de lectura.

Posteriormente, el script utiliza los nombres de las muestras para definir la estructura de salida y crear, con `mkdir -p "$OUTDIR"`, los subdirectorios necesarios donde se guardarán los resultados del alineamiento generados por **STAR**. Se usa un punto de control con if para revisar que todos los R1 tengan su pareja con R2, si no es el caso emite un error indicando cual pareja fallo.

La siguiente parte del script corresponde a la ejecución de **STAR** utilizando las variables definidas previamente.

- **runThreadN**: Define el número de hilos de CPU que utilizará STAR durante el alineamiento. Este valor suele asignarse en el encabezado del script para que el gestor de colas (`sbatch`) reserve los recursos necesarios.

- **genomeDir**: Directorio donde se encuentra el índice del genoma generado previamente.

- **readFilesIn**: Archivos de lecturas de entrada. En este caso corresponden a las lecturas emparejadas **R1** y **R2** de cada muestra.

- **readFilesCommand**: Indica a STAR que los archivos de entrada están comprimidos (`.gz`). De esta forma, el programa los descomprime en tiempo real durante el análisis, evitando la necesidad de descomprimirlos previamente.

- **outFileNamePrefix**: Define el prefijo y la ubicación donde STAR guardará los archivos de salida generados para cada muestra.

- **outSAMtype BAM SortedByCoordinate**: Indica que el archivo de alineamiento final debe generarse en formato **BAM** y ordenado por **coordenadas genómicas**.

- **quantMode GeneCounts**: Hace que STAR genere, además del alineamiento, un archivo con el número de lecturas asignadas a cada gen.

El comando `quantMode` crea un archivo conteos que puede servir para hacer el analisis diferencial, pero crea cada archivo para cada muestra en su respectivo sub-directorio, por lo que si se quiere trabajar con los datos se puede unir esa informacion en 1 solo archivo con el script `merge_star_tab.sh`.

Este script reúne los archivos `ReadsPerGene.out.tab` generados por **STAR** para cada muestra y los combina en una única matriz de conteos por gen. Para ello, recorre automáticamente las subcarpetas de `star_results`, extrae la columna de conteos de cada muestra y las une en una sola tabla.

Además, el script utiliza el archivo de anotaciones **GTF** para añadir el **gene_name** correspondiente a cada `gene_id`. Como resultado, se genera el archivo final `star_counts_matrix_annotated.tsv`, que contiene la matriz de expresión génica para todas las muestras junto con su anotación básica.

## Conteo usando FeatureCounts 

La principal ventaja de **featureCounts** es que ofrece mayor flexibilidad y control sobre el proceso de asignación de lecturas, permitiendo especificar parámetros como el tipo de librería, el manejo de lecturas emparejadas o los criterios de asignación a genes. Por este motivo, es una herramienta ampliamente utilizada en pipelines de RNA-seq para generar matrices de expresión génica que posteriormente se utilizan en análisis de expresión diferencial.

Como paso previo al conteo de lecturas, es necesario determinar si las secuencias conservan información sobre la hebra de origen del RNA. En función de esto, las librerías de RNA-seq pueden clasificarse como **unstranded**, **stranded** o **reverse stranded**. Esta información normalmente puede verificarse en los metadatos del experimento o en la documentación del protocolo de preparación de librerías utilizado durante la secuenciación. Sin embargo, si esta información no está disponible, es posible inferirla empíricamente.

Para ello, antes de realizar el conteo definitivo con featureCounts, se puede ejecutar un conteo de prueba utilizando una misma muestra y repitiendo el análisis tres veces, cambiando el parámetro `-s` (0, 1 y 2). Posteriormente se comparan los porcentajes de lecturas asignadas que devuelve **Subread**, y el valor que produce el mayor porcentaje de asignación suele corresponder al tipo de librería. Para facilitar esta comprobación se incluye el script `test_stranded.sh`, que puede ejecutarse con `bash` desde la consola. El usuario solo necesita indicar la ruta a una muestra `.bam`, y el script ejecutará los tres conteos necesarios para evaluar la orientación de las lecturas.

```bash
SAMPLE=" "

featureCounts -a ref/Salmo_salar.Ssal_v3.1.115.gtf -o test_s0.txt -T 4 -t exon -g gene_id -p -B -C -s 0 "$SAMPLE"

```

Una vez con la informacion lista se puede ejecutar el script conteos_featurecounts.




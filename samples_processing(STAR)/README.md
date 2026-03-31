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
      --quantMode TrnascriptomeSAM GeneCounts
   
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

- **quantMode TranscriptomeSAM**: Este parámetro indica a **STAR** que genere el archivo `Aligned.toTranscriptome.out.bam`, el cual contiene las lecturas alineadas a nivel de transcriptoma y puede utilizarse como entrada en herramientas como **RSEM**.

*Es fundamental tener en cuenta las herramientas que se utilizarán en el downstream analysis. Si se desea emplear **RSEM** para la cuantificación y no se ha activado la opción `TranscriptomeSAM` durante el alineamiento con STAR, no será posible ejecutar RSEM correctamente. En ese caso, será necesario volver a ejecutar STAR con este parámetro habilitado.*

### Conteo de genes usando las funciones de STAR.

El comando `quantMode` crea un archivo conteos que puede servir para hacer el analisis diferencial, pero crea cada archivo para cada muestra en su respectivo sub-directorio, por lo que si se quiere trabajar con los datos se puede unir esa informacion en 1 solo archivo con el script `merge_star_tab.sh`.

Este script reúne los archivos `ReadsPerGene.out.tab` generados por **STAR** para cada muestra y los combina en una única matriz de conteos por gen. Para ello, recorre automáticamente las subcarpetas de `star_results`, extrae la columna de conteos de cada muestra y las une en una sola tabla.

Además, el script utiliza el archivo de anotaciones **GTF** para añadir el **gene_name** correspondiente a cada `gene_id`. Como resultado, se genera el archivo final `star_counts_matrix_annotated.tsv`, que contiene la matriz de expresión génica para todas las muestras junto con su anotación básica.

## Conteo usando RSEM para cuantificacion.

El programa RSEM por sus siglas en ingles (RNA-seq by Expectation-Maximication) es una plataforma de osftware de cuantificacion de expresion de muestras de RNA-seq. El software toma las lecturas mapeadas de un trasncriptoma y las estima frente a una referencia de trasncriptos. Dentro del software este estima las abundancias de genes y de sus respectivas isoformas dando como resultado una mayor cantidad de datos para trabajar. Este software es mucho mas lento y pesado porque, como se explica, realiza una estimacion de la abundacia de genes y no solo cuenta los genes como lo hace Samtools. Su rasgo clave es que para estimar la abundancia utuliza un algoritmo de `Maximum-Expectation` para repartir de forma probabilistica las lecturas que pueden corresponder a mas de un trascrito.

Para ejecutar RSEM, este debe separarse en 2 partes. Primero hace falta desarrollar una referencia adaptada a RSEM, para esto se prepara un script que utiliza los archivos previamente usados en STAR, el genoma de referencia y sus anotaciones (`.GTF y .FASTA`). El script usa la funcion de RSEM `rsem-prepare-reference` cargando los archivos y su formato en el comando de la funcion. Este generara una gran cantidad de archivos por lo que se recomienda crear un directorio donde guardar todos los archivos.


## Cuantificación de expresión con RSEM

El programa RSEM (RNA-Seq by Expectation-Maximization) es una herramienta de software diseñada para la cuantificación de la expresión génica en datos de RNA-seq. A diferencia de métodos basados únicamente en conteo, RSEM utiliza las lecturas previamente alineadas frente a un transcriptoma o genoma de referencia para **estimar la abundancia de genes y sus isoformas**.

Dentro del proceso, RSEM asigna probabilísticamente las lecturas a los distintos transcritos, lo que permite obtener estimaciones más precisas, especialmente en casos donde una misma lectura puede mapear en múltiples isoformas. Para ello, utiliza un algoritmo de tipo **Expectation-Maximization (EM)**, que reparte las lecturas ambiguas en función de la probabilidad de pertenecer a cada transcrito.

Debido a este enfoque basado en estimación, RSEM es una herramienta **más exigente en términos de tiempo de ejecución y recursos computacionales** en comparación con métodos de conteo directo, como los basados en **featureCounts** o **STAR GeneCounts**, que asignan lecturas de forma más directa.


### Preparación de la referencia para RSEM

La ejecución de RSEM requiere una preparación previa de una referencia específica. Para ello, se utiliza la función `rsem-prepare-reference`, que genera todos los archivos necesarios a partir del genoma de referencia (`.FASTA`) y sus anotaciones (`.GTF`).

En este pipeline, se emplean los mismos archivos utilizados previamente en STAR. El proceso se automatiza mediante un script que ejecuta `rsem-prepare-reference`, indicando las rutas a los archivos de entrada y el formato correspondiente.

Este paso genera un número considerable de archivos auxiliares, por lo que se recomienda crear un directorio específico para almacenar la referencia de RSEM y mantener organizada la estructura del proyecto.

```
 rsem-prepare-reference 
      --gtf "$GTF" \
      "$FASTA" \
      "$RSEM_REF"
```
### Ejecución de RSEM

Una vez preparada la referencia, el siguiente paso es la cuantificación de la expresión utilizando **RSEM** mediante la función `rsem-calculate-expression`. Este proceso toma como entrada las lecturas alineadas o directamente los archivos FASTQ, y estima la abundancia de genes y transcritos.

En esta pipeline, RSEM se ejecuta a partir de las lecturas alineadas previamente con STAR, utilizando el archivo `Aligned.toTranscriptome.out.bam`, que contiene los alineamientos proyectados sobre el transcriptoma.

Mediante un algoritmo de tipo **Expectation-Maximization (EM)**, RSEM distribuye probabilísticamente las lecturas ambiguas entre los distintos transcritos. Este proceso se realiza de forma iterativa hasta alcanzar una estimación estable.

A partir de esta asignación, RSEM calcula distintas medidas de abundancia:
- **expected_counts** → número estimado de lecturas asignadas  
- **TPM (Transcripts Per Million)** → normalización entre muestras  
- **FPKM** → normalización basada en longitud y profundidad

Para cada muestra, RSEM genera varios archivos, entre los que destacan:

- `sample.genes.results` → abundancia a nivel de gen  
- `sample.isoforms.results` → abundancia a nivel de transcrito  

El uso de RSEM permite obtener una estimación más precisa de la expresión génica, especialmente en presencia de isoformas. Sin embargo, este enfoque implica un mayor coste computacional en comparación con métodos de conteo directo como **featureCounts**.

### Unión de resultados en una misma matriz

Para facilitar el análisis posterior en **R**, es necesario combinar los resultados de todas las muestras en una única matriz de expresión. Para esto se desarrollo el script `merge_RSEM.sh`, cuya función es procesar automáticamente los archivos `.genes.results` generados por RSEM y construir la matriz `rsem_gene_expected_count_matrix.tsv`.

El script recorre el directorio de resultados de RSEM y localiza todos los archivos `.genes.results`, que contienen la información de abundancia a nivel de gen para cada muestra. A partir del nombre de cada archivo, se identifica el nombre de la muestra, que posteriormente se utilizará como nombre de columna en la matriz final.

Para cada archivo, el script extrae dos columnas clave:
- **gene_id** → identificador del gen  
- **expected_count** → número estimado de lecturas asignadas a ese gen  

Durante este proceso, el script guarda la lista de genes a partir de una de las muestras como referencia común, asegurando que todas las muestras se alineen correctamente por `gene_id`.

Posteriormente, se extrae la columna de **expected counts** de cada muestra y se almacena de forma temporal. Una vez procesadas todas las muestras, el script combina estas columnas utilizando herramientas como `paste`, generando una tabla en la que:

- Cada **fila** representa un gen  
- Cada **columna** corresponde a una muestra  
- Los valores corresponden a los **expected counts** estimados por RSEM  

Finalmente, el script añade una cabecera con los nombres de las muestras y genera el archivo `rsem_gene_expected_count_matrix.tsv`, que constituye la matriz de expresión génica.

Y se puede pasar a realizar los analisis estadisticos en R.



# RNA-seq pipeline with STAR and RSEM

Este repositorio contiene la organización base de un flujo de trabajo para el análisis de datos de **RNA-seq** en entorno **SLURM**, incluyendo las etapas de preprocesamiento, procesamiento bioinformático y análisis en R.

El objetivo de esta distribución es mantener una estructura clara, reproducible y escalable, facilitando la ejecución ordenada de cada etapa del análisis y la posterior interpretación de resultados.


## Estructura general del repositorio

```bash
.
├── 0.pre-processing_samples
├── 1.processing_samples(STAR)
└── 2.analysis_samples(R)
```


## Descripción de carpetas

### `0.pre-processing_samples`

Esta carpeta contiene el script en Bash (`.sh`) encargado de generar la estructura de carpetas del proyecto para su ejecución en el directorio de trabajo.

Su función principal es preparar el entorno de trabajo antes del análisis, creando una organización homogénea para todas las muestras u órganos incluidos en el estudio. Esta etapa es importante porque permite que los scripts posteriores trabajen sobre una estructura fija y predecible, reduciendo errores y mejorando la reproducibilidad del pipeline.

---
### `1.processing_samples(STAR)`

Esta carpeta contiene los scripts de procesamiento bioinformático de las muestras. Aquí se incluyen las etapas principales del pipeline, desde la limpieza de lecturas hasta la alineación y cuantificación.

En esta fase se trabaja con herramientas como:

- **fastp**: para control de calidad, filtrado y recorte de lecturas.
- **STAR**: para la alineación de lecturas contra el genoma de referencia.
- **RSEM**: para la cuantificación de expresión génica o transcriptómica a partir de los alineamientos generados.

Esta carpeta representa el núcleo del procesamiento de datos crudos de RNA-seq.

---

### `2.analysis_samples(R)`

Esta carpeta contiene el archivo `deseq2.Rmd` utilizado para el análisis en **R** de los resultados generados en la fase anterior.

Aquí se realiza la exploración, organización, análisis estadístico y representación de los datos de expresión obtenidos tras el procesamiento con STAR y RSEM. 

---

## Requisitos generales

Este repositorio está orientado a análisis de RNA-seq en entorno Linux/HPC. Dependiendo de la etapa, pueden ser necesarios:

- **Bash**
- **SLURM**
- **fastp**
- **STAR**
- **RSEM**
- **R**
- Paquetes de análisis en R incluidos en el archivo `.Rmd`

---

## Notas

- La estructura del repositorio puede ampliarse a medida que avance el proyecto.
- Se recomienda mantener nombres de carpetas y scripts consistentes para evitar errores en rutas.
- Cada etapa del pipeline está separada para favorecer un análisis modular y reutilizable.

---

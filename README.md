# Proyecto Integrador — Almacenes y Minería de Datos

**Sitio publicado:** <https://data-mining-gg.github.io/proyecto/>

## Tema

**Detección de fraude y estimación de confianza en transacciones fintech.**

Detectar cuándo una transacción se aparta del comportamiento habitual de **esa cuenta en particular**
—más allá de reglas fijas iguales para todos— y decirlo con un nivel de **confianza** explícito, para
poder bloquear automáticamente lo que es casi seguro fraude, mandar a revisión humana lo dudoso, y no
friccionar al resto. Pregunta guía: *¿cómo sabemos si una transacción es fraude, y con qué seguridad
lo decimos?*

El proyecto se construye de forma incremental siguiendo **CRISP-DM**.

| Entrega | Fase CRISP-DM | Contenido |
|---|---|---|
| E0 · Comprensión del Negocio | 1 | Objetivo de negocio y de minería, preguntas P1–P4, criterio de éxito |
| E1 · Arquitectura del DW | 2 (inicio) | Catálogo de fuentes verificado, arquitectura staging → DW → DataMart en BigQuery, esquema estrella y matriz de trazabilidad |

## Estructura del repositorio

```
.
├── _quarto.yml                       # configuración del sitio (output-dir: docs)
├── index.qmd                         # portada
├── docs/                             # sitio compilado que sirve GitHub Pages
├── entregas/
│   ├── E0_comprension_negocio/
│   │   ├── index.qmd                 # resumen de la entrega E0
│   │   ├── bitacora.qmd              # bitácora de la reunión con el stakeholder
│   │   ├── canvas.qmd                # Business Understanding Canvas (1 página)
│   │   ├── preguntas.qmd             # preguntas de investigación priorizadas
│   │   ├── criterio_exito.qmd        # criterio de éxito en términos de negocio
│   │   ├── riesgos_supuestos.qmd     # supuestos y riesgos
│   │   ├── uso_ia.qmd                # documentación de uso de LLMs
│   │   └── fuentes/
│   │       └── referencias.qmd       # fuentes verificables (stakeholder simulado)
│   └── E1_arquitectura_dw/
│       ├── index.qmd                 # resumen de la entrega E1
│       ├── fuentes.qmd               # búsqueda documentada, catálogo e integración
│       ├── arquitectura.qmd          # 3 capas, evidencia BigQuery, consultas del mart
│       ├── estrella.qmd              # grano, diagrama Mermaid y DDL
│       ├── trazabilidad.qmd          # matriz pregunta-métrica-dimensión-fuente
│       ├── uso_ia.qmd                # documentación de uso de LLMs
│       ├── sql/                      # 00_datasets, 01_staging, ddl_dw, consultas_mart
│       ├── scripts/muestreo.py       # muestras < 100 MB para staging
│       ├── diagramas/                # arquitectura.excalidraw
│       └── img/                      # capturas de BigQuery
```

## Integrantes

| Nombre | Número de cuenta |
|---|---|
| Vega Navas Saúl | 322088267 |
| Cimmino Yáñez Nicholas Joseph | 322490712 |
| Benítez Pérez Kristian Leonel | 322011346 |
| Herrera Cuamatla Jennifer Jade | 322255481 |

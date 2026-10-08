-- PaySim e IEEE-CIS se suben como CSV desde la consola (muestras de muestreo.py).
-- ULB ya está en BigQuery, así que solo se copia.

CREATE OR REPLACE TABLE fraude_staging.ulb_creditcard
OPTIONS (description = 'Copia de bigquery-public-data.ml_datasets.ulb_fraud_detection')
AS
SELECT *
FROM `bigquery-public-data.ml_datasets.ulb_fraud_detection`;

SELECT COUNT(*) AS filas, SUM(Class) AS fraudes
FROM fraude_staging.ulb_creditcard;

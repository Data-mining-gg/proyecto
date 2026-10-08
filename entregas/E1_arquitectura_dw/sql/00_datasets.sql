-- Los tres datasets en US (la tabla pública de ULB también está en US)

CREATE SCHEMA IF NOT EXISTS fraude_staging
  OPTIONS (location = 'US', description = 'Staging: datos crudos de cada fuente');

CREATE SCHEMA IF NOT EXISTS fraude_dw
  OPTIONS (location = 'US', description = 'DW: esquema estrella');

CREATE SCHEMA IF NOT EXISTS fraude_mart
  OPTIONS (location = 'US', description = 'DataMart: una vista por pregunta (P1-P4)');

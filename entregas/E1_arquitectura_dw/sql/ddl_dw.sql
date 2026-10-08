-- Esquema estrella. Grano: una fila por transacción.

CREATE OR REPLACE TABLE fraude_dw.dim_fuente (
  fuente_key        INT64  NOT NULL,
  nombre_fuente     STRING OPTIONS (description = 'PaySim | IEEE-CIS | ULB'),
  propietario       STRING,
  url_origen        STRING,
  licencia          STRING,
  es_sintetica      BOOL,
  moneda            STRING,
  dominio           STRING OPTIONS (description = 'dinero movil | e-commerce | tarjeta de credito'),
  fecha_carga       DATE,
  PRIMARY KEY (fuente_key) NOT ENFORCED
)
OPTIONS (description = 'SCD1. Responde: P2, P3, P4');

-- fecha_key = dia_relativo * 100 + hora (ej. día 29 a las 14 h -> 2914)
CREATE OR REPLACE TABLE fraude_dw.dim_fecha (
  fecha_key         INT64  NOT NULL,
  dia_relativo      INT64,
  hora_del_dia      INT64,
  hora_absoluta     INT64,
  semana_relativa   INT64,
  franja_horaria    STRING OPTIONS (description = 'madrugada | manana | tarde | noche'),
  es_nocturna       BOOL,
  PRIMARY KEY (fecha_key) NOT ENFORCED
)
OPTIONS (description = 'Tiempo relativo dia-hora. SCD0. Responde: P1, P3, P4');

CREATE OR REPLACE TABLE fraude_dw.dim_tipo_transaccion (
  tipo_key              INT64  NOT NULL,
  fuente_key            INT64,
  codigo_original       STRING OPTIONS (description = 'type (PaySim) | ProductCD (IEEE-CIS) | TARJETA (ULB)'),
  categoria_conformada  STRING,
  canal                 STRING,
  PRIMARY KEY (tipo_key) NOT ENFORCED,
  FOREIGN KEY (fuente_key) REFERENCES fraude_dw.dim_fuente (fuente_key) NOT ENFORCED
)
OPTIONS (description = 'SCD1. Responde: P2, P3');

-- cuenta_key = 0 es la cuenta desconocida (ULB y el destino de IEEE-CIS)
CREATE OR REPLACE TABLE fraude_dw.dim_cuenta (
  cuenta_key                 INT64  NOT NULL,
  fuente_key                 INT64  NOT NULL,
  id_cuenta_natural          STRING,
  tipo_cuenta                STRING OPTIONS (description = 'CLIENTE | COMERCIO | TARJETA | DESCONOCIDA'),
  primer_dia_actividad       INT64,
  perfil_num_transacciones   INT64,
  perfil_monto_medio         FLOAT64,
  perfil_monto_desv          FLOAT64,
  perfil_monto_max           FLOAT64,
  valido_desde_dia           INT64,
  valido_hasta_dia           INT64,
  es_version_actual          BOOL,
  PRIMARY KEY (cuenta_key) NOT ENFORCED,
  FOREIGN KEY (fuente_key) REFERENCES fraude_dw.dim_fuente (fuente_key) NOT ENFORCED
)
OPTIONS (description = 'Perfil por cuenta. SCD2. Responde: P1, P4');

CREATE OR REPLACE TABLE fraude_dw.hechos_transaccion (
  id_transaccion_origen  STRING NOT NULL,
  fuente_key             INT64  NOT NULL,
  fecha_key              INT64  NOT NULL,
  tipo_key               INT64  NOT NULL,
  cuenta_origen_key      INT64  NOT NULL,
  cuenta_destino_key     INT64  NOT NULL,
  num_transacciones      INT64,
  monto                  FLOAT64 OPTIONS (description = 'No sumar entre fuentes (monedas distintas)'),
  es_fraude              INT64,
  es_marcada_por_regla   INT64 OPTIONS (description = 'isFlaggedFraud de PaySim'),
  saldo_origen_antes     FLOAT64 OPTIONS (description = 'Solo PaySim, no usar para modelar'),
  saldo_origen_despues   FLOAT64 OPTIONS (description = 'Solo PaySim, no usar para modelar'),
  PRIMARY KEY (fuente_key, id_transaccion_origen) NOT ENFORCED,
  FOREIGN KEY (fuente_key)         REFERENCES fraude_dw.dim_fuente (fuente_key) NOT ENFORCED,
  FOREIGN KEY (fecha_key)          REFERENCES fraude_dw.dim_fecha (fecha_key) NOT ENFORCED,
  FOREIGN KEY (tipo_key)           REFERENCES fraude_dw.dim_tipo_transaccion (tipo_key) NOT ENFORCED,
  FOREIGN KEY (cuenta_origen_key)  REFERENCES fraude_dw.dim_cuenta (cuenta_key) NOT ENFORCED,
  FOREIGN KEY (cuenta_destino_key) REFERENCES fraude_dw.dim_cuenta (cuenta_key) NOT ENFORCED
)
OPTIONS (description = 'Grano: una fila por transaccion. Responde: P1, P2, P3, P4');

-- P1: cada transacción contra el historial previo de su cuenta
-- (cuenta destino en PaySim, tarjeta en IEEE-CIS)
CREATE OR REPLACE VIEW fraude_mart.vw_p1_desviacion_vs_historial
OPTIONS (description = 'Responde: P1')
AS
WITH base AS (
  SELECT
    h.fuente_key,
    h.id_transaccion_origen,
    IF(h.cuenta_destino_key <> 0, h.cuenta_destino_key, h.cuenta_origen_key) AS cuenta_perfil_key,
    f.hora_absoluta,
    h.monto,
    h.es_fraude
  FROM fraude_dw.hechos_transaccion AS h
  JOIN fraude_dw.dim_fecha AS f USING (fecha_key)
  WHERE h.cuenta_destino_key <> 0 OR h.cuenta_origen_key <> 0
),
historial AS (
  SELECT
    *,
    COUNT(*)            OVER w_previas AS n_previas,
    AVG(monto)          OVER w_previas AS monto_medio_previo,
    STDDEV_SAMP(monto)  OVER w_previas AS monto_desv_previo,
    MAX(monto)          OVER w_previas AS monto_max_previo,
    hora_absoluta - LAG(hora_absoluta) OVER (
      PARTITION BY fuente_key, cuenta_perfil_key
      ORDER BY hora_absoluta, id_transaccion_origen
    ) AS horas_desde_previa
  FROM base
  WINDOW w_previas AS (
    PARTITION BY fuente_key, cuenta_perfil_key
    ORDER BY hora_absoluta, id_transaccion_origen
    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
  )
)
SELECT
  fuente_key,
  id_transaccion_origen,
  cuenta_perfil_key,
  hora_absoluta,
  monto,
  n_previas,
  monto_medio_previo,
  SAFE_DIVIDE(monto - monto_medio_previo, monto_desv_previo) AS z_monto_vs_historial,
  monto > monto_max_previo                                   AS supera_max_historico,
  horas_desde_previa,
  n_previas = 0                                              AS sin_historial,
  es_fraude
FROM historial;

-- P2: fraude vs legítimo por tipo de dato, fuente y categoría
CREATE OR REPLACE VIEW fraude_mart.vw_p2_perfil_fraude_por_fuente
OPTIONS (description = 'Responde: P2')
AS
SELECT
  s.nombre_fuente,
  s.es_sintetica,
  t.categoria_conformada,
  GROUPING(s.nombre_fuente)        AS agrupa_fuente,
  GROUPING(t.categoria_conformada) AS agrupa_categoria,
  SUM(h.num_transacciones)                             AS transacciones,
  SUM(h.es_fraude)                                     AS fraudes,
  SAFE_DIVIDE(SUM(h.es_fraude), SUM(h.num_transacciones)) AS tasa_fraude,
  AVG(IF(h.es_fraude = 1, h.monto, NULL))              AS monto_medio_fraude,
  AVG(IF(h.es_fraude = 0, h.monto, NULL))              AS monto_medio_legitimo
FROM fraude_dw.hechos_transaccion AS h
JOIN fraude_dw.dim_fuente AS s USING (fuente_key)
JOIN fraude_dw.dim_tipo_transaccion AS t USING (tipo_key)
GROUP BY GROUPING SETS (
  (s.es_sintetica),
  (s.es_sintetica, s.nombre_fuente),
  (s.es_sintetica, s.nombre_fuente, t.categoria_conformada)
);

-- P3: costo de la regla fija por decil de monto (4.59 x monto no detectado + falsos positivos)
CREATE OR REPLACE VIEW fraude_mart.vw_p3_costo_por_decil_monto
OPTIONS (description = 'Responde: P3')
AS
WITH con_decil AS (
  SELECT
    h.*,
    NTILE(10) OVER (PARTITION BY h.fuente_key ORDER BY h.monto) AS decil_monto
  FROM fraude_dw.hechos_transaccion AS h
)
SELECT
  s.nombre_fuente,
  t.categoria_conformada,
  c.decil_monto,
  SUM(c.num_transacciones)                                          AS transacciones,
  SUM(c.es_fraude)                                                  AS fraudes,
  SUM(IF(c.es_fraude = 1, c.monto, 0))                              AS monto_fraude,
  SUM(IF(c.es_fraude = 1 AND c.es_marcada_por_regla = 1, c.monto, 0)) AS monto_fraude_capturado_regla,
  SAFE_DIVIDE(
    SUM(IF(c.es_fraude = 1 AND c.es_marcada_por_regla = 1, c.monto, 0)),
    SUM(IF(c.es_fraude = 1, c.monto, 0)))                           AS recall_monto_regla,
  SUM(IF(c.es_fraude = 0 AND c.es_marcada_por_regla = 1, 1, 0))     AS falsos_positivos_regla,
  4.59 * SUM(IF(c.es_fraude = 1 AND IFNULL(c.es_marcada_por_regla, 0) = 0, c.monto, 0))
    + SUM(IF(c.es_fraude = 0 AND c.es_marcada_por_regla = 1, 1, 0)) AS costo_esperado_regla
FROM con_decil AS c
JOIN fraude_dw.dim_fuente AS s USING (fuente_key)
JOIN fraude_dw.dim_tipo_transaccion AS t USING (tipo_key)
GROUP BY ROLLUP (s.nombre_fuente, t.categoria_conformada, c.decil_monto)
-- sin total general porque mezclaría monedas
HAVING GROUPING(s.nombre_fuente) = 0;

-- P4: indicadores semanales por fuente y su cambio
CREATE OR REPLACE VIEW fraude_mart.vw_p4_estabilidad_semanal
OPTIONS (description = 'Responde: P4')
AS
WITH semanal AS (
  SELECT
    s.nombre_fuente,
    f.semana_relativa,
    SUM(h.num_transacciones)                                  AS transacciones,
    SAFE_DIVIDE(SUM(h.es_fraude), SUM(h.num_transacciones))   AS tasa_fraude,
    AVG(h.monto)                                              AS monto_medio,
    SAFE_DIVIDE(COUNTIF(c.primer_dia_actividad = f.dia_relativo),
                SUM(h.num_transacciones))                     AS proporcion_cuentas_nuevas
  FROM fraude_dw.hechos_transaccion AS h
  JOIN fraude_dw.dim_fuente AS s USING (fuente_key)
  JOIN fraude_dw.dim_fecha  AS f USING (fecha_key)
  LEFT JOIN fraude_dw.dim_cuenta AS c
    ON c.cuenta_key = IF(h.cuenta_destino_key <> 0, h.cuenta_destino_key, h.cuenta_origen_key)
  GROUP BY s.nombre_fuente, f.semana_relativa
)
SELECT
  *,
  AVG(tasa_fraude) OVER (
    PARTITION BY nombre_fuente ORDER BY semana_relativa
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)                 AS tasa_fraude_media_movil_3s,
  tasa_fraude - LAG(tasa_fraude) OVER (
    PARTITION BY nombre_fuente ORDER BY semana_relativa)      AS cambio_tasa_vs_semana_previa,
  SAFE_DIVIDE(monto_medio, LAG(monto_medio) OVER (
    PARTITION BY nombre_fuente ORDER BY semana_relativa)) - 1 AS cambio_rel_monto_medio
FROM semanal;

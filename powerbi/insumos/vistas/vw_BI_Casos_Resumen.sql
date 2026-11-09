-- Vista para Power BI: vw_BI_Casos_Resumen
-- Resumen general de casos (I/P/C/R)
-- Generada a partir de powerbi/insumos/queries/Casos_Resumen.sql
-- Cambios frente a la query original: se quitan los filtros @proyecto/@Grupo/@FECHAINI/@FECHAFIN y el ORDER BY (se filtra en Power BI); se agregan 49_Id_Proyecto y 50_Id_Grupo.
-- Tiempos: TODOS en minutos (columnas *_Min; cronómetros = minutos hábiles). La conversión a horas/días se hace en Power BI.
-- ⚠ 30_Tiempo_Min (current_time) y 31_Progreso_del_caso (congelado) no son confiables: usar los cronómetros 32–35 (ver manual, sección 1).
-- Ejecutar en SSMS sobre la base de Aranda con un usuario que tenga permiso CREATE VIEW (DBA).
CREATE OR ALTER VIEW bi.vw_BI_Casos_Resumen
AS
WITH
campos as (
SELECT
ASMS_FIELDS.id ID_CAMPO,
ASMS_FIELDS.name AS campo,
ASMS_FIELDS.model_id	as modelo,
ASMS_FIELDS_DATA.string_value VALOR_STRING,
ASMS_FIELDS_DATA.int_value	valorint,
ASMS_FIELDS_DATA.date_value	valordate,
ASMS_FIELDS_DATA.item_id ID_CASO
FROM ASMS_FIELDS_DATA
LEFT OUTER JOIN ASMS_FIELDS ON ASMS_FIELDS.id = ASMS_FIELDS_DATA.field_id
union all
SELECT
ASMS_FIELDS.id ID_CAMPO,
ASMS_FIELDS.name AS campo,
ASMS_FIELDS.model_id	as modelo,
ASMS_FIELDS_DATA_CLOSED.string_value VALOR_STRING,
ASMS_FIELDS_DATA_CLOSED.int_value	valorint,
ASMS_FIELDS_DATA_CLOSED.date_value	valordate,
ASMS_FIELDS_DATA_CLOSED.item_id ID_CASO
FROM ASMS_FIELDS_DATA_CLOSED
LEFT OUTER JOIN ASMS_FIELDS ON ASMS_FIELDS.id = ASMS_FIELDS_DATA_CLOSED.field_id
)

SELECT
  caso.[id]                                                  [id]
 ,ASMS_PROJECTS.proj_name                                   [01_Proyecto]
 ,ASMS_TYPES.name                                           [02_Tipo_de_Caso]
 ,caso.id_by_project										[03_Numero_de_Caso]
 ,ASDK_CATEGORY.ctg_caption                                 [04_Categoria]
 ,DT.subject	                                            [05_Asunto]
 ,ASDK_CATEGORY.fl_str_hierarchy                            [06_Jerarquia]
 ,ASDK_SERVICE.name						                    [07_Servicio]
 ,aut.user_name			                                    [08_Autor_del_Caso]
 ,cli.user_name                                             [09_Cliente]
 ,res.user_name			                                    [10_Responsable]
 ,AFW_GROUPS.grou_name                                      [11_Grupo_Responsable]
 ,ASMS_STATUS.stat_name                                     [12_Estado]
 ,ASMS_STATUS_REASON.reas_description                       [13_Razon]
 ,cli.user_nick_name							            [14_Cliente_Alias]
 ,Depart.code_key											[15_Departamento]
 ,sites.code_key											[16_Sede]
 ,edifi.code_key											[17_Edificio]
 ,dateadd(HH,-5,caso.opened_date)							[18_Fecha_de_Registro]
 ,dateadd(HH,-5,caso.closed_date)                           [19_Fecha_de_Cierre]
 ,registro.code_value										[20_Tipo_de_Registro]
 ,modi.user_name											[21_Ultimo_Esp_Modificador]
 ,(
	SELECT top 1 INICIO
	FROM (
		SELECT t.name, td.item_id, td.sdb_current_time, dateadd(HH,-5,td.estimated_date) INICIO, td.end_date FIN
		FROM ASMS_TIMES_DATA td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Attention')
		UNION ALL
		SELECT t.name, td.item_id caso, td.sdb_current_time, dateadd(HH,-5,td.estimated_date) INICIO, td.end_date FIN
		FROM ASMS_TIMES_DATA_CLOSED td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Attention')
	) s
	PIVOT ( MAX(sdb_current_time) FOR name IN ([Attention]) ) p
	where item_id = CASO.id    order by [Attention] desc
	)					                                 [22_Fecha_Atencion_Estimada]
 ,(
	SELECT top 1 FIN
	FROM (
		SELECT t.name, td.item_id, td.sdb_current_time, dateadd(HH,-5,td.end_date) FIN
		FROM ASMS_TIMES_DATA td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Attention')
		UNION ALL
		SELECT t.name, td.item_id caso, td.sdb_current_time, dateadd(HH,-5,td.end_date) FIN
		FROM ASMS_TIMES_DATA_CLOSED td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Attention')
	) s
	PIVOT ( MAX(sdb_current_time) FOR name IN (Attention) ) p
	where item_id = CASO.id    order by [Attention] desc
	)														[23_Fecha_Atencion_Real]
 ,(
	SELECT top 1 INICIO
	FROM (
		SELECT t.name, td.item_id, td.sdb_current_time, dateadd(HH,-5,td.estimated_date) INICIO, td.end_date FIN
		FROM ASMS_TIMES_DATA td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Solution')
		UNION ALL
		SELECT t.name, td.item_id caso, td.sdb_current_time, dateadd(HH,-5,td.estimated_date) INICIO, td.end_date FIN
		FROM ASMS_TIMES_DATA_CLOSED td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Solution')
	) s
	PIVOT ( MAX(sdb_current_time) FOR name IN ([Solution]) ) p
	where item_id = CASO.id    order by [Solution] desc
	)														[24_Fecha_Solucion_Estimada]
 ,(
	SELECT top 1 FIN
	FROM (
		SELECT t.name, td.item_id, td.sdb_current_time, dateadd(HH,-5,td.end_date) FIN
		FROM ASMS_TIMES_DATA td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Solution')
		UNION ALL
		SELECT t.name, td.item_id caso, td.sdb_current_time, dateadd(HH,-5,td.end_date) FIN
		FROM ASMS_TIMES_DATA_CLOSED td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Solution')
	) s
	PIVOT ( MAX(sdb_current_time) FOR name IN (Solution) ) p
	where item_id = CASO.id    order by [Solution] desc
)																[25_Fecha_Solucion_Real]
 ,impacto.code_value											[26_Impacto]
 ,Urgencia.code_value											[27_Urgencia]
 ,Prioridad.code_value											[28_Prioridad]
 ,ASDK_SLA.NAME													[29_SLA]
 ,ROUND(CASO.[current_time], 2)                              [30_Tiempo_Min]
 ,ROUND(caso.current_progress, 2)                   [31_Progreso_del_caso]
 ,ROUND((
	SELECT top 1 [Attention]
	FROM (
		SELECT t.name, td.item_id, td.estimated_time
		FROM ASMS_TIMES_DATA td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Attention')
		UNION ALL
		SELECT t.name, td.item_id caso, td.estimated_time
		FROM ASMS_TIMES_DATA_CLOSED td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Attention')
	) s
	PIVOT ( MAX(estimated_time) FOR name IN ([Attention]) ) p
	where item_id = CASO.id    order by [Attention] DESC
	), 2)                           [32_Tiempo_Atencion_Estimado_Min]
 ,ROUND((
	SELECT top 1 [Attention]
	FROM (
		SELECT t.name, td.item_id, td.sdb_current_time
		FROM ASMS_TIMES_DATA td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Attention')
		UNION ALL
		SELECT t.name, td.item_id caso, td.sdb_current_time
		FROM ASMS_TIMES_DATA_CLOSED td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Attention')
	) s
	PIVOT ( MAX(sdb_current_time) FOR name IN ([Attention]) ) p
	where item_id = CASO.id    order by [Attention] DESC
	), 2)              [33_Tiempo_Atencion_Real_Min]
 ,ROUND((
	SELECT top 1 [Solution]
	FROM (
		SELECT t.name, td.item_id, td.estimated_time
		FROM ASMS_TIMES_DATA td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Solution')
		UNION ALL
		SELECT t.name, td.item_id caso, td.estimated_time
		FROM ASMS_TIMES_DATA_CLOSED td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Solution')
	) s
	PIVOT ( MAX(estimated_time) FOR name IN ([Solution]) ) p
	where item_id = CASO.id    order by [Solution] DESC
	), 2)                           [34_Tiempo_Solucion_Estimado_Min]
 ,ROUND( (
	SELECT top 1 [Solution]
	FROM (
		SELECT t.name, td.item_id, td.sdb_current_time
		FROM ASMS_TIMES_DATA td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Solution')
		UNION ALL
		SELECT t.name, td.item_id caso, td.sdb_current_time
		FROM ASMS_TIMES_DATA_CLOSED td
		JOIN ASMS_TIMES t ON t.id = td.time_id
		WHERE t.name IN('Solution')
	) s
	PIVOT ( MAX(sdb_current_time) FOR name IN ([Solution]) ) p
	where item_id = CASO.id    order by [Solution] DESC
	)
       ,2)                                                  [35_Tiempo_Solucion_Real_Min]
  /*
  CONCAT(
         CAST(FLOOR(CONVERT(Numeric(18, 2),  Isnull([Tiempo_Atencion], 0)) / (8 * 60))                  AS VARCHAR(100)), ':', --' días ',--de 8 horas habiles
         CAST(FLOOR((CONVERT(Numeric(18, 2), Isnull([Tiempo_Atencion], 0)) % (8 * 60)) / 60)            AS VARCHAR(100)), ':', --' horas ',
         CAST(FLOOR(CONVERT(Numeric(18, 2),  Isnull([Tiempo_Atencion], 0)) % 60)                        AS VARCHAR(100)), ':', --' minutos ',
         CAST(CONVERT(INT, ROUND((CONVERT(Numeric(18, 4), Isnull([Tiempo_Atencion], 0)) * 60) % 60, 0)) AS VARCHAR(100))       --' segundos'
         ) AS [Tiempo_Atencion_Estimado_DHMS]
  */
 ,ISNULL((SELECT STRING_AGG(id_by_project,', ') caso_rel
FROM (
   SELECT target_id, id_by_project
   FROM ASDK_ITEM_RELATION ir
   JOIN adw.FACT_ASDK_ITEM it ON it.id = ir.source_id AND ir.target_id = caso.id
   WHERE IT.item_type_sk=1
   UNION ALL
   SELECT target_id, id_by_project
   FROM ASDK_ITEM_RELATION_CLOSED ir
   JOIN adw.FACT_ASDK_ITEM it ON it.id = ir.source_id AND ir.target_id = caso.id
   WHERE IT.item_type_sk=1
) TEMP
GROUP BY target_id), 'Sin casos relacionado')                                                    [36_Incidentes_Relacionados]
 ,ISNULL((SELECT STRING_AGG(id_by_project,', ') caso_rel
FROM (
   SELECT target_id, id_by_project
   FROM ASDK_ITEM_RELATION ir
   JOIN adw.FACT_ASDK_ITEM it ON it.id = ir.source_id AND ir.target_id = caso.id
   WHERE IT.item_type_sk=2
   UNION ALL
   SELECT target_id, id_by_project
   FROM ASDK_ITEM_RELATION_CLOSED ir
   JOIN adw.FACT_ASDK_ITEM it ON it.id = ir.source_id AND ir.target_id = caso.id
   WHERE IT.item_type_sk=2
) TEMP
GROUP BY target_id), 'Sin casos relacionado')                                                    [37_Problemas_Relacionados]
 ,ISNULL((SELECT STRING_AGG(id_by_project,', ') caso_rel
FROM (
   SELECT target_id, id_by_project
   FROM ASDK_ITEM_RELATION ir
   JOIN adw.FACT_ASDK_ITEM it ON it.id = ir.source_id AND ir.target_id = caso.id
   WHERE IT.item_type_sk=3
   UNION ALL
   SELECT target_id, id_by_project
   FROM ASDK_ITEM_RELATION_CLOSED ir
   JOIN adw.FACT_ASDK_ITEM it ON it.id = ir.source_id AND ir.target_id = caso.id
   WHERE IT.item_type_sk=3
) TEMP
GROUP BY target_id), 'Sin casos relacionado')                                                    [38_Cambios_Relacionados]
 ,ISNULL((SELECT STRING_AGG(id_by_project,', ') caso_rel
FROM (
   SELECT target_id, id_by_project
   FROM ASDK_ITEM_RELATION ir
   JOIN adw.FACT_ASDK_ITEM it ON it.id = ir.source_id AND ir.target_id = caso.id
   WHERE IT.item_type_sk=4
   UNION ALL
   SELECT target_id, id_by_project
   FROM ASDK_ITEM_RELATION_CLOSED ir
   JOIN adw.FACT_ASDK_ITEM it ON it.id = ir.source_id AND ir.target_id = caso.id
   WHERE IT.item_type_sk=4
) TEMP
GROUP BY target_id), 'Sin casos relacionado')                                                    [39_Requerimientos_Relacionados]
 ,dt.commentary_nohtml                                   [41_Comentario_de_Solucion]
 ,CMDB_CI.name                                             [42_CI_Asociado]
 ,CMDB_CI.id                                                  [43_ID]
 ,DT.description_nohtml                                  [48_Descripcion]
 ,caso.project_sk                                        [49_Id_Proyecto]
 ,caso.specialist_group_sk                               [50_Id_Grupo]
FROM adw.FACT_ASDK_ITEM                         caso

left join ASMS_PROJECTS	on	ASMS_PROJECTS.proj_id	= caso.project_sk
left join ASMS_TYPES	on	ASMS_TYPES.id			= caso.item_type_sk
left join ASDK_CATEGORY	on	ASDK_CATEGORY.ctg_index	= caso.category_sk
left join [adw].[DIM_ASDK_ITEM_TEXT] DT	ON DT.item_sk = caso.id AND DT.is_current = 1
left join ASDK_SERVICE	on	ASDK_SERVICE.id			= caso.service_sk
left join AFW_USERS aut	on	aut.user_id				= caso.author_user_sk
left join AFW_USERS cli	on	cli.user_id				= caso.customer_user_sk
left join AFW_USERS res	on	res.user_id				= caso.specialist_user_sk
left join AFW_GROUPS	on  AFW_GROUPS.grou_id		= caso.specialist_group_sk
LEFT JOIN ASMS_STATUS	ON ASMS_STATUS.stat_id		= caso.status_sk
LEFT JOIN ASMS_STATUS_REASON	ON ASMS_STATUS_REASON.reas_id	=	caso.reason_sk
LEFT JOIN AFW_CATALOG_CODE Depart	ON Depart.code_id	= cli.user_department_code
LEFT JOIN AFW_CATALOG_CODE sites	ON sites.code_id	= cli.user_site_id
LEFT JOIN AFW_CATALOG_CODE edifi	ON edifi.code_id	= cli.user_building_id
left join (SELECT iptacc.code_cata_id, iptacc.code_id, iptacc.code_value
           FROM AFW_CATALOG AFCATA
           INNER JOIN AFW_CATALOG_CODE iptacc ON AFCATA.cata_id = iptacc.code_cata_id AND AFCATA.cata_name = 'REGISTRY_TYPE') as registro on registro.code_id = caso.registry_type_sk
left join AFW_USERS modi	on	modi.user_id				= caso.modifier_user_sk
left join (SELECT iptacc.code_cata_id, iptacc.code_id, iptacc.code_value
           FROM AFW_CATALOG AFCATA
           INNER JOIN AFW_CATALOG_CODE iptacc ON AFCATA.cata_id = iptacc.code_cata_id AND AFCATA.cata_name = 'IMPACT') as impacto on impacto.code_id = caso.impact_sk
left join (SELECT iptacc.code_cata_id, iptacc.code_id, iptacc.code_value
           FROM AFW_CATALOG AFCATA
           INNER JOIN AFW_CATALOG_CODE iptacc ON AFCATA.cata_id = iptacc.code_cata_id AND AFCATA.cata_name = 'URGENCY') as Urgencia on Urgencia.code_id = caso.urgency_sk
left join (SELECT iptacc.code_cata_id, iptacc.code_id, iptacc.code_value
           FROM AFW_CATALOG AFCATA
           INNER JOIN AFW_CATALOG_CODE iptacc ON AFCATA.cata_id = iptacc.code_cata_id AND AFCATA.cata_name = 'PRIORITY') as Prioridad on Prioridad.code_id = caso.priority_sk
LEFT JOIN ASDK_SLA	ON ASDK_SLA.SLA_ID	=   caso.sla_sk
LEFT JOIN CMDB_CI	ON	CMDB_CI.id	=	CASO.ci_sk

WHERE CASO.item_type_sk IN (1,2,3,4)
GO

-- Origen: SQL Server | Base: Aranda Device Management (ADM / AAM)
-- Tabla en Power BI: Inventario_ADM
-- Descripción: Inventario de dispositivos activos con agente, sus aplicaciones instaladas y su sistema operativo
-- Granularidad: una fila por dispositivo + aplicación (+ IP y grupo, puede duplicar filas)
WITH cte_operating_system AS (
    SELECT
        ds.device_id,
        pr.name product_name_so,
        (sv.version) version_so
    FROM
        AAM_SOFTWARE_PRODUCT pr
        LEFT JOIN AAM_SOFTWARE_VERSION sv ON sv.product_id = pr.id
        LEFT JOIN AAM_DEVICE_SOFTWARE ds ON sv.id = ds.software_id
        JOIN [dbo].[AAM_DEVICE_OS] os ON ds.id = os.id
    WHERE
        pr.type = 0 -- 0: sistema operativo
        AND ds.device_id IS NOT NULL
)
SELECT
    D.id Device_id,
    UPPER(D.name) Device_name,
    UPPER(DST.system_product) Device_model,
    UPPER(D.domain) Device_domain,
    UPPER(D.username) Device_username,
    D.created_date Device_created_date,
    UPPER(DT.name) Device_type,
    UPPER(SP.name) Software,
    CASE
        SP.type
        WHEN 0 THEN 'SISTEMA OPERATIVO'
        WHEN 1 THEN 'APLICACIONES'
        WHEN 2 THEN 'ACTUALIZACIONES'
    END AS Software_type,
    SV.version Software_version,
    ISNULL(UPPER(M.name), 'UNKNOWN') Manufacturer_software,
    CN.address Device_ip,
    ISNULL(UPPER(G.grou_name), 'SIN GRUPO') Group_name,
    OS.version_so Operating_system_version,
    UPPER(OS.product_name_so) Operating_system
FROM
    dbo.AAM_DEVICE D
    LEFT JOIN dbo.AAM_DEVICE_SOFTWARE AS DS ON D.id = DS.device_id
    AND DS.system_component = 0
    LEFT JOIN dbo.AAM_DEVICE_TYPE DT ON D.type = DT.id
    LEFT JOIN dbo.AAM_SOFTWARE_VERSION AS SV ON SV.id = DS.software_id
    LEFT JOIN dbo.AAM_SOFTWARE_PRODUCT AS SP ON SP.id = SV.product_id
    LEFT JOIN ADM_COMMUNICATION_NODE CN ON D.id = CN.device_id
    LEFT JOIN AAM_MANUFACTURER M ON SP.manufacturer_id = m.id
    LEFT JOIN AAM_DEVICE_SETUP DST ON D.id = DST.device_id
    LEFT JOIN AAM_GROUP_DEVICE GD ON D.id = gd.device_id
    LEFT JOIN AFW_GROUPS G ON GD.group_id = G.grou_id
    LEFT JOIN cte_operating_system OS ON D.id = OS.device_id
    LEFT JOIN AAM_DEVICE_CONFIGURATION DC ON D.id = DC.device_id
WHERE
    SP.type = 1
    AND DC.agent_version IS NOT NULL
    AND D.is_active = 1

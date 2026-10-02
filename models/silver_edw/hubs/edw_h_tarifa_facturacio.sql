{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'hub']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(TIP_TARIFA)) AS TIP_TARIFA,
        UPPER(TRIM(SUBTIP_TARIFA)) AS SUBTIP_TARIFA,
        DATA_INI_VIGENCIA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM {{ ref('l4_tarifa_facturacio') }}

    WHERE NULLIF(TRIM(TIP_TARIFA), '') IS NOT NULL
      AND NULLIF(TRIM(SUBTIP_TARIFA), '') IS NOT NULL
      AND DATA_INI_VIGENCIA IS NOT NULL

),

hashed_source AS (

    SELECT
        SHA2_HEX(
            CONCAT_WS(
                '|',
                TIP_TARIFA,
                SUBTIP_TARIFA,
                TO_VARCHAR(DATA_INI_VIGENCIA, 'YYYY-MM-DD')
            ),
            256
        ) AS HK_TARIFA_FACTURACIO,

        TIP_TARIFA,
        SUBTIP_TARIFA,
        DATA_INI_VIGENCIA,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

SELECT
    src.HK_TARIFA_FACTURACIO,

    src.TIP_TARIFA,
    src.SUBTIP_TARIFA,
    src.DATA_INI_VIGENCIA,

    src.ID_CARGA,
    src.FECHA_EXTRACCION,

    CONVERT_TIMEZONE(
        'Europe/Madrid',
        CURRENT_TIMESTAMP()
    ) AS FECHA_CARGA,

    src.SISTEMA_ORIGEN,
    'L4_TARIFA_FACTURACIO' AS TABLA_ORIGEN

FROM hashed_source AS src

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} AS target
    WHERE target.HK_TARIFA_FACTURACIO = src.HK_TARIFA_FACTURACIO

)

{% endif %}

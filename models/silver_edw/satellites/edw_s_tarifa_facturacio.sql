{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='silver_edw',
    tags=['silver_edw', 'data_vault', 'satellite']
) }}

WITH source_data AS (

    SELECT
        UPPER(TRIM(TIP_TARIFA)) AS TIP_TARIFA,
        UPPER(TRIM(SUBTIP_TARIFA)) AS SUBTIP_TARIFA,
        DATA_INI_VIGENCIA,

        DATA_FI_VIGENCIA,
        ORDRE,
        VALOR_NUMERIC,
        UPPER(TRIM(UNITAT)) AS UNITAT,
        OBSERVACIONS,

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

        SHA2_HEX(
            CONCAT_WS(
                '|',
                COALESCE(TO_VARCHAR(DATA_FI_VIGENCIA, 'YYYY-MM-DD'), '^^'),
                COALESCE(TO_VARCHAR(ORDRE), '^^'),
                COALESCE(
                    TO_VARCHAR(
                        VALOR_NUMERIC,
                        'FM999999999999990.0000'
                    ),
                    '^^'
                ),
                COALESCE(UNITAT, '^^'),
                COALESCE(NULLIF(TRIM(OBSERVACIONS), ''), '^^')
            ),
            256
        ) AS HASHDIFF,

        TIP_TARIFA,
        SUBTIP_TARIFA,
        DATA_INI_VIGENCIA,

        DATA_FI_VIGENCIA,
        ORDRE,
        VALOR_NUMERIC,
        UNITAT,
        OBSERVACIONS,

        ID_CARGA,
        FECHA_EXTRACCION,
        SISTEMA_ORIGEN

    FROM source_data

)

{% if is_incremental() %}

,

latest_target AS (

    SELECT
        HK_TARIFA_FACTURACIO,
        HASHDIFF

    FROM {{ this }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_TARIFA_FACTURACIO
        ORDER BY
            FECHA_CARGA DESC,
            FECHA_EXTRACCION DESC,
            ID_CARGA DESC
    ) = 1

)

{% endif %}

SELECT
    src.HK_TARIFA_FACTURACIO,
    src.HASHDIFF,

    src.TIP_TARIFA,
    src.SUBTIP_TARIFA,
    src.DATA_INI_VIGENCIA,

    src.DATA_FI_VIGENCIA,
    src.ORDRE,
    src.VALOR_NUMERIC,
    src.UNITAT,
    src.OBSERVACIONS,

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

LEFT JOIN latest_target AS target
    ON target.HK_TARIFA_FACTURACIO = src.HK_TARIFA_FACTURACIO

WHERE target.HK_TARIFA_FACTURACIO IS NULL
   OR target.HASHDIFF <> src.HASHDIFF

{% endif %}

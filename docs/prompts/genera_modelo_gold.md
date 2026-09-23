# Prompt para GitHub Copilot: capa Gold dimensional para Power BI

## Objetivo

Actúa como arquitecto de datos sénior especializado en **dbt, Snowflake, modelado dimensional Kimball y Power BI**.

La estructura en capas del modelo de datos para el proyecto Agua Clara es la siguiente:

raw_sicab
    -> l4_fact (bronze)
        -> silver_fact (modelo estándar del negocio de facturación)
        -> silver_edw (modelo corporativo Data Vault 2.0)
            -> gold_fact (modelo estrella para analítica / Power BI)

La diferenciación entre `silver_fact` y `silver_edw` es importante:

- `silver_fact`: capa de negocio para facturación, con modelado estándar y prefijo `S_`.
- `silver_edw`: capa corporativa de entidades compartidas y reutilizables, con modelado Data Vault 2.0 y prefijos `EDW_H_`, `EDW_L_` y `EDW_S_` para hubs, links y satellites.
- `gold_fact`: capa final analítica, con modelo dimensional en estrella para consumo de BI.

Actualmente, ya se dispone de los modelos para las capas RAW, L4_FACT, SILVER_EDW y SILVER_FACT, estando materializados y testeados.

Tu tarea es diseñar y generar una capa **GOLD en estrella**, optimizada para su explotación desde Power BI.

No modifiques los modelos existentes de RAW, L4 o Silver. Si detectas un problema bloqueante, documéntalo antes de continuar.

---

## Forma de trabajo obligatoria

Trabaja en dos fases.

### Fase 1: inspección y diseño

Antes de crear archivos:

1. Inspecciona todos los modelos SQL y YAML de `SILVER_FACT` y `SILVER_EDW`.
2. Identifica para cada modelo:
   - granularidad;
   - clave primaria o clave de negocio;
   - claves foráneas;
   - medidas;
   - atributos descriptivos;
   - historificación disponible;
   - cardinalidad esperada;
   - campos técnicos que no deberían exponerse en Power BI.
3. No inventes modelos ni columnas. Usa exclusivamente lo que exista en el repositorio.
4. Presenta una propuesta que incluya:
   - inventario de fuentes Silver;
   - dimensiones conformadas;
   - tablas de hechos;
   - granularidad de cada tabla Gold;
   - relaciones y cardinalidades;
   - tratamiento de históricos;
   - estrategia incremental;
   - riesgos de duplicación de importes;
   - diagrama Mermaid del modelo estrella.
5. Detente al finalizar esta fase. No generes todavía los modelos Gold hasta recibir aprobación.

### Fase 2: generación

Después de que la propuesta sea aprobada:

1. Crea los modelos Gold.
2. Crea los tests y reconciliaciones.
3. Crea la documentación YAML.
4. Crea la exposición de Power BI.
5. Revisa referencias, claves, granularidades y riesgo de multiplicación de filas.

---

## Fuentes Silver que debes inspeccionar

Comprueba los nombres reales del repositorio. Presta especial atención, si existen, a modelos equivalentes a:

- `s_factura`
- `s_factura_concepto`
- `s_factura_situacion_hist`
- `s_factura_recup`
- `s_factura_regul`
- `s_servicio_ci_facturar`
- suministro o póliza
- cliente
- finca
- ramal
- geografía
- tarifa
- concepto
- situación de factura
- colectivo social
- actividad económica
- fraude

Adapta el diseño a los modelos y columnas que existan realmente.

---

## Reglas de negocio obligatorias

### Composición de la factura

1. Los componentes procedentes de `FACT_AIGUA` representan importes del servicio de agua.
2. Los conceptos procedentes de `FACT_CONCEPTE` representan conceptos adicionales, incluidos canon del agua, conservación, tasas, bonificaciones y equipos contra incendios.
3. El canon del agua es un tributo adicional. No es el precio del consumo de agua.
4. Los conceptos `AIGUA_BLOC*` y los conceptos `CA*` son diferentes y aditivos.
5. Los conceptos `CL1` y `CL2` fueron eliminados en origen porque duplicaban el alcantarillado.
6. El alcantarillado se representa con un único concepto `CLAVEGUERAM`, derivado de `FACT_AIGUA.IMP_CLAVAG`.

### Conceptos derivados de FACT_AIGUA

En Silver se han verticalizado, entre otros, estos conceptos:

- `AIGUA_BLOC1`
- `AIGUA_BLOC2`
- `AIGUA_BLOC3`
- `AIGUA_BLOC4`
- `AIGUA_BLOC5`
- `QUOTA_SERVEI`
- `CT_XBASICA`
- `TCG_SUBM`
- `CLAVEGUERAM`
- `SANEJAMENT`
- `ERSU`
- `CIH_BLOC1`
- `CIH_BLOC2`
- `CIH_BLOC3`
- `IVA_SANEJAMENT`
- `IVA`

### Reglas de cuadre

Las reglas definitivas son:

```text
S_FACTURA.IMP_AIGUA_IVA
=
SUM(S_FACTURA_CONCEPTO.IMP_CONCEPTE)
para conceptos cuyo origen sea L4_FACT_AIGUA
```

```text
S_FACTURA.IMP_TOTAL_FACT
=
SUM(S_FACTURA_CONCEPTO.IMP_CONCEPTE)
para todos los conceptos aditivos de la factura
```

```text
S_FACTURA.CONSUM_TOTAL_M3
=
SUM(S_FACTURA_CONCEPTO.QUANTITAT)
para AIGUA_BLOC1, AIGUA_BLOC2, AIGUA_BLOC3, AIGUA_BLOC4 y AIGUA_BLOC5
```

Tolerancias máximas:

- importes: `0,01`;
- volúmenes: `0,000001`.

### Suministros contra incendios

Las facturas CI:

- tienen cabecera de factura;
- tienen conceptos explícitos de equipos;
- no tienen fila vacía en `FACT_AIGUA`;
- no deben contener conceptos cuyo origen sea `L4_FACT_AIGUA`.

### Recuperaciones y regularizaciones

Gold debe permitir analizar recuperaciones y regularizaciones sin duplicar importes.

Debe conservar:

- factura asociada;
- suministro;
- fechas;
- importe total;
- volumen total;
- componentes recuperados o regularizados;
- periodo o fin de incidencia cuando exista.

---

## Modelo Gold orientativo

Valida esta propuesta contra las fuentes reales y modifícala si es necesario.

### Dimensiones

- `g_d_fecha`
- `g_d_cliente`
- `g_d_suministro`
- `g_d_geografia`
- `g_d_concepto`
- `g_d_situacion_factura`
- `g_d_tarifa`, si aporta valor y existe información suficiente
- `g_d_colectivo_social`, si existe información suficiente
- `g_d_actividad_economica`, si existe información suficiente

### Hechos

#### `g_h_factura`

Grano: una factura y partición.

Medidas esperadas, si existen en Silver:

- consumo total;
- importe de agua con IVA;
- importe total;
- indicadores de recuperación y regularización;
- número de conceptos.

Contiene detalle acerca de: 
- suministro;
- fecha;

#### `g_h_factura_concepto`

Grano: una línea de concepto de factura.

Debe incluir, si existen:

- factura;
- concepto;
- cantidad;
- precio unitario;
- base;
- porcentaje;
- importe;
- IVA;
- tabla de origen.

#### `g_h_factura_situacion`

Grano: un cambio de situación de factura.

#### `g_h_recuperacion`

Grano: el definido por el modelo Silver real de recuperaciones.

#### `g_h_regularizacion`

Grano: el definido por el modelo Silver real, previsiblemente factura y fecha de fin de incidencia.

#### `g_h_servicio_ci`

Créala únicamente si aporta valor analítico separado y Silver dispone de una fuente adecuada.

---

## Diseño para Power BI

El modelo debe favorecer:

- esquema en estrella;
- relaciones uno a muchos;
- filtro unidireccional desde dimensiones hacia hechos;
- dimensiones conformadas compartidas;
- ausencia de relaciones muchos a muchos salvo necesidad justificada;
- jerarquías de fecha y geografía;
- medidas simples y auditables;
- mínimo DAX complejo;
- actualización incremental cuando exista una marca temporal fiable.

Evita:

- relaciones bidireccionales;
- snowflakes innecesarios;
- mezcla de granularidades;
- joins entre hechos que multipliquen importes;
- claves hash expuestas como campos normales para usuarios;
- dimensiones creadas con `ROW_NUMBER()` no determinista.

Crea miembros desconocidos cuando sean necesarios:

```text
SK = -1
codigo = DESCONOCIDO
descripcion = Desconocido
```

---

## Clasificación de conceptos

`g_d_concepto` debe unificar los conceptos de ambas procedencias e incluir, cuando sea posible:

- código;
- descripción;
- grupo funcional;
- naturaleza económica;
- tabla de origen;
- indicador de consumo;
- indicador de servicio;
- indicador de tributo;
- indicador de bonificación;
- indicador de IVA;
- indicador aditivo.

Clasificación funcional mínima:

- `CONSUMO_AGUA`
- `CUOTA_SERVICIO`
- `CANON_AGUA`
- `INFRAESTRUCTURA_HIDRAULICA`
- `ALCANTARILLADO`
- `SANEAMIENTO`
- `RESIDUOS`
- `CONSERVACION`
- `BONIFICACION`
- `EQUIPO_CI`
- `IVA`
- `OTROS`

No inventes clasificaciones sin justificar la correspondencia con los códigos existentes.

---

## Materializaciones

Propón la materialización más adecuada:

- dimensiones pequeñas: `table`;
- hechos: `incremental` con `merge`, cuando sea seguro;
- auxiliares: `view`, salvo necesidad de rendimiento;
- `g_d_fecha`: `table`.

Para cada modelo incremental:

- define una `unique_key` estable;
- usa una marca temporal fiable;
- contempla actualizaciones retroactivas;
- no dependas únicamente de la fecha de emisión si los datos pueden cambiar por recuperación, regularización o estado posterior.

Si no existe una marca temporal fiable, prioriza la corrección y documenta por qué el modelo se materializa como `table`.

---

## Estructura de archivos esperada

```text
models/gold_fact/
├── dimensiones/
│   ├── g_d_fecha.sql
│   ├── g_d_cliente.sql
│   ├── g_d_suministro.sql
│   ├── g_d_geografia.sql
│   ├── g_d_concepto.sql
│   └── ...
├── hechos/
│   ├── g_h_factura.sql
│   ├── g_h_factura_concepto.sql
│   ├── g_h_factura_situacion.sql
│   ├── g_h_recuperacion.sql
│   ├── g_h_regularizacion.sql
│   └── ...
├── intermediate/
│   └── solo modelos auxiliares necesarios
├── schema.yml
└── exposures.yml
```

Adapta la estructura a las convenciones reales del repositorio.

---

## Tests obligatorios

### Claves e integridad

- `unique`
- `not_null`
- `relationships`
- ausencia de duplicados según la granularidad declarada
- uso del miembro desconocido cuando corresponda

### Reconciliación Silver a Gold

Comprueba:

- mismo número de facturas;
- misma suma de `IMP_TOTAL_FACT`;
- misma suma de `IMP_AIGUA_IVA`;
- mismo consumo total;
- mismo número e importe de líneas de concepto;
- mismo número, importe y volumen de recuperaciones;
- mismo número, importe y volumen de regularizaciones;
- misma distribución por tipo de suministro;
- misma distribución por año y mes.

### Consistencia interna Gold

```text
g_h_factura.importe_agua_iva
=
SUM(g_h_factura_concepto.importe)
para conceptos cuyo origen sea L4_FACT_AIGUA
```

```text
g_h_factura.importe_total
=
SUM(g_h_factura_concepto.importe)
para todos los conceptos aditivos
```

```text
g_h_factura.consumo_total_m3
=
SUM(g_h_factura_concepto.cantidad)
para AIGUA_BLOC1 a AIGUA_BLOC5
```

### Recuperaciones

- recuento;
- claves ausentes;
- claves adicionales;
- importe total;
- volumen total;
- correspondencia con la factura.

### Regularizaciones

- recuento;
- claves ausentes;
- claves adicionales;
- importe total;
- volumen total;
- correspondencia con factura y periodo de incidencia.

Los tests singulares deben devolver exclusivamente filas incorrectas. Una ejecución correcta debe devolver cero filas.

---

## Documentación y exposición

Genera `schema.yml` con:

- descripción de cada modelo;
- granularidad;
- propósito;
- claves primarias y foráneas;
- descripción funcional de columnas;
- tests;
- clasificación de medidas como aditivas, semiaditivas o no aditivas;
- metadatos útiles para Power BI.

Genera una exposición dbt para Power BI, por ejemplo:

```yaml
name: power_bi_facturacion_agua_clara
type: dashboard
maturity: medium
```

Incluye como dependencias todos los hechos y dimensiones destinados al modelo semántico.

---

## Entregables de la Fase 2

1. Modelos SQL Gold.
2. `schema.yml`.
3. `exposures.yml`.
4. Tests de reconciliación Silver a Gold.
5. Tests de consistencia interna Gold.
6. Documento Markdown de diseño.
7. Diagrama Mermaid.
8. Lista de medidas Power BI recomendadas, sin crear todavía un archivo PBIX.
9. Resumen de archivos creados, decisiones, supuestos y riesgos pendientes.

---

## Restricciones

- No generes datos sintéticos nuevos.
- No cambies valores de Silver.
- No inventes columnas.
- No uses `SELECT *` en los modelos finales.
- No dependas del orden físico de columnas.
- No mezcles granularidades.
- No ocultes descuadres mediante tolerancias amplias.
- No excluyas conceptos mediante listas arbitrarias.
- No añadas excepciones para `CL1` o `CL2`, porque ya fueron eliminados en origen.
- No uses relaciones muchos a muchos sin justificación.
- No des por terminada la tarea si quedan referencias a modelos inexistentes, columnas inventadas o tests incompletos.
- Todo el SQL debe ser compatible con Snowflake y respetar las convenciones del proyecto.

---

## Criterios de aceptación

La solución será aceptable si:

- presenta un esquema en estrella claro;
- no modifica Silver;
- no inventa campos;
- documenta la granularidad de cada tabla;
- evita multiplicar filas o importes;
- los importes de agua cuadran con conceptos de origen `L4_FACT_AIGUA`;
- el total de factura cuadra con todos los conceptos aditivos;
- el canon permanece separado del consumo de agua;
- recuperaciones y regularizaciones quedan reconciliadas;
- las facturas CI no reciben conceptos de `L4_FACT_AIGUA`;
- las relaciones son aptas para Power BI;
- los tests correctos devuelven cero filas.

---

## Instrucción inicial

Ejecuta únicamente la **Fase 1**.

Inspecciona el repositorio y entrega la propuesta de diseño Gold. No crees todavía archivos SQL o YAML de Gold. Espera mi aprobación antes de ejecutar la Fase 2.

# Proyecto Agua Clara
## 1. Introducción y propósito del proyecto

Proyecto para un piloto de pruebas de facturación de servicios de agua en dbt + Snowflake + Coalesce (linaje) + Airflow (orquestación) + Power BI. El objetivo del piloto es la formación de un equipo de trabajo en estas tecnologías para, llegado el caso, acometer proyectos reales basados en las mismas para una empresa de aguas.

## 2. Población del piloto

El piloto contiene **100 suministros**, identificados mediante `POLISSA_SUBM` con valores comprendidos entre `S000000001` y `S000000100`.

La clasificación funcional principal es la siguiente:

- **S000000001 a S000000070**: suministros domésticos. En `SUBMIN_SERVEI`, estos registros se identifican normalmente mediante `TIP_SUBM_SERV = 'D'` y `US_AIGUA_SUBM = '1'`. Todos están activos (`SIT_SUBM_SERV = 'A'`).
- **S000000071 a S000000094**: suministros industriales. En `SUBMIN_SERVEI`, se identifican mediante `TIP_SUBM_SERV = 'I'` y `US_AIGUA_SUBM = '4'`. De estos, 9 están en baja (`SIT_SUBM_SERV = 'B'`): `S000000086` a `S000000094`.
- **S000000095 a S000000100**: servicios de equipos contra incendios, denominados en este documento servicios **CI**. En `SUBMIN_SERVEI`, se identifican mediante `TIP_SUBM_SERV = 'C'`. La letra `C` no debe interpretarse como comercial en este piloto, sino como servicio contra incendios. De estos, 2 están en baja: `S000000098` y `S000000099`.

Además de esa clasificación general, existen casos especiales:

- **Suministros vulnerables**: `S000000021`, `S000000034`, `S000000058` y `S000000069`. La vulnerabilidad no se aplica automáticamente a toda la vida del suministro. Deben respetarse los intervalos de vigencia de `HIST_SS_PE`.
- **Suministros en situación de fraude**: `S000000023` y `S000000091`, incluidos en `CONVENI_FRAU`. Un suministro se considera en situación de fraude desde `DATA_CREA_C_FRA` mientras el registro permanezca en la tabla.
- **Suministros sujetos a TAMGREM**: `S000000071` a `S000000096`, según los registros presentes en `PADRO_TAMGREM`. Este rango incluye los 24 suministros industriales (`S000000071` a `S000000094`) y también dos suministros CI (`S000000095` y `S000000096`). La aplicación efectiva debe depender de la existencia y vigencia del registro en el padrón, no solo del rango numérico de la póliza.

## 3. Principios generales del modelo

- La tabla central de suministros es `SUBMIN_SERVEI`.

- Las tablas territoriales y técnicas describen dónde se encuentra el suministro, qué ramal lo abastece y qué características tiene. Las tablas de padrón y de histórico aportan circunstancias adicionales, como la actividad económica, la tasa de residuos, TAMGREM, vulnerabilidad, equipos CI o fraude.

- Las tablas de facturas (FACT_RESUM, SITUACIO_FACT, FACT_AIGUA y FACT_CONCEPTE) registran la facturación del suministro a lo largo del tiempo y son la fuente principal de los datos a analizar en Power BI: consumos e importes facturados. Las relaciones padre-hija entre estas tablas de facturas utilizan la clave lógica de factura:

```text
ID_EMPRESA
ANY_FACTURA
NUM_FACTURA
```

En las tablas que incluyen `NUM_PARTICIO`, este valor forma parte de la clave primaria propia de la tabla, pero la relación con `FACT_RESUM` se mantiene mediante las tres columnas anteriores.

## 4. Definición funcional de las tablas

### 4.1. CODIFICACIONS

`CODIFICACIONS` es el catálogo general de valores codificados. Su clave primaria es:

```text
TIP_CODI
CLAU_CODI
```

El CSV disponible es:

```text
codifications.csv
```

Para la facturación son especialmente relevantes dos familias:

- `TIP_CODI = 'F25'`: conceptos utilizados en facturación ordinaria.
- `TIP_CODI = 'R01'`: situaciones o estados de factura.

Los códigos de concepto introducidos en `FACT_CONCEPTE.NUM_CONCEPTE` deben existir en la familia `F25`.

Entre los códigos `F25` relevantes se encuentran:

```text
CA1  Canon de agua doméstico, tramo 1
CA2  Canon de agua doméstico, tramo 2
CA6  Canon de agua doméstico, tramo 3
CA7  Canon de agua doméstico, tramo 4
CA3  Canon de agua industrial, gravamen general
CA4  Canon de agua industrial, gravamen específico
CA5  IVA del canon del agua
CL1  Tasa de alcantarillado, tramo 1
CL2  Tasa de alcantarillado, tramo 2
B25  Bocas de 25
B45  Bocas de 45
B70  Bocas de 70
B10  Bocas de 100
SPR  Sprinklers
TAM  TAMGREM
IVN  IVA normal, utilizado para bocas
IVE  IVA especial o de servicios
BOS  Bonificación de cuota social
BSA  Bonificación social de agua
BSQ  Bonificación social de cuota
BTD  Bonificación TMTR por uso de puntos limpios
CON  Conservación de contador
```

Los códigos `R01` contienen los estados reales de factura. Entre los más relevantes están:

```text
00  En proceso de facturación
01  Emitida y cargada a recaudación
02  Cargo a entidad de cobro
03  Cobrada
04  Devuelta
05  Cancelada
06  Anulada pendiente de reintegrar
07  Anulada y reintegrada
12  Cobrada parcialmente
14  En suspensión de cobro
18  Pendiente de cancelar
20  Aplazada
23  Reclamada con carta recordatoria
24  Reclamada
31  Pendiente de cargo a morosos
34  Anulada sin reintegro
37  Bloqueada
39  Cobrada total
```

`SITUACIO_FACT.TIP_SIT_FACT` utiliza códigos válidos de `R01`.

### 4.2. MUNICIPI_SGAB

Es el maestro municipal. El CSV disponible es:

```text
municipi_sgab.csv
```

Su clave primaria es `NUM_MUN_SGAB`. Entre sus campos relevantes están `ID_EMPRESA`, provincia, delegación, agencia y distintos indicadores municipales. En el piloto, `ID_EMPRESA` es habitualmente `AB`.

Esta tabla es padre de `DTE_MUNICIPAL` y `CARRER`.

### 4.3. DTE_MUNICIPAL

Contiene los distritos municipales y depende de `MUNICIPI_SGAB` mediante `NUM_MUN_SGAB`. El CSV disponible es:

```text
dte_municipal.csv
```

Su clave primaria es:

```text
NUM_MUN_SGAB
NUM_DTE_MUNI
```

### 4.4. EPIGRAF_IAE

Es el catálogo de actividades económicas utilizadas en el piloto. El CSV disponible es:

```text
epigraf_iae.csv
```

Su clave primaria es:

```text
SECCIO
EPIGRAF_IAE
```

La sección permite identificar grandes grupos funcionales:

```text
U  Doméstico o uso particular
C  Comercio
I  Industria
S  Servicios
A  Administración pública
E  Entidades y asociaciones
P  Profesionales
```

Los epígrafes industriales `4101` a `4106` son especialmente importantes para calcular consumos industriales sintéticos.

### 4.5. CARRER

Maestro de calles. El CSV disponible es:

```text
carrer.csv
```

Depende de `MUNICIPI_SGAB` y su clave es:

```text
NUM_MUN_SGAB
NUM_CARRER
```

### 4.6. FINCA

Contiene las fincas en las que se ubican los ramales. El CSV disponible es:

```text
finca.csv
```

Depende de `CARRER`. Su clave es compuesta y reproduce la identificación completa de la finca.

### 4.7. RAMAL

Describe la acometida o ramal asociado a una finca. El CSV disponible es:

```text
ramal.csv
```

La clave primaria es `POLISSA_RAMAL`. Depende de `FINCA` mediante la clave completa de finca.

Entre sus campos relevantes están el diámetro, uso del ramal, estado, fecha de instalación, fecha de baja y datos territoriales. `SUBMIN_SERVEI.POLISSA_RAMAL` relaciona cada suministro con su ramal.

### 4.8. SUBMIN_SERVEI

Es la tabla principal de contratos o suministros. El CSV disponible es:

```text
submin_servei.csv
```

Su clave primaria es `POLISSA_SUBM`.

Los campos más importantes para la generación de facturación son:

- `POLISSA_SUBM`: identificador de suministro.
- `TIP_SUBM_SERV`: tipo principal de suministro. En el piloto, `D` es doméstico, `I` es industrial y `C` es CI.
- `SIT_SUBM_SERV`: situación actual del suministro. `A` representa activo y `B` baja en los datos sintéticos.
- `DATA_ALT_SUBM_SERV`: fecha de alta. No se debe generar ningún periodo anterior a esta fecha.
- `DATA_RES_SUBM_SERV`: fecha de resolución o baja. No se debe generar ningún periodo posterior a esta fecha.
- `DATA_ULTIMA_FACT`: fecha de última factura registrada en el maestro. Es informativa y no sustituye al calendario que debe generarse.
- `US_AIGUA_SUBM`: uso del agua. Los domésticos usan normalmente `1`, los industriales `4` y los CI `2`.
- `NOMB_HABIT_SUBM`: número de habitantes. Es relevante para consumo doméstico y ampliaciones o bonificaciones.
- `TIP_HABIT_SUBM`: tipo de vivienda. Puede relacionarse con las cuotas de servicio.
- `TIP_TAXA_TRR`: tipo de tasa TRR.
- `DNI_NIF_CLIENT`, datos bancarios, idioma y nombre del titular: deben copiarse a `FACT_RESUM` cuando exista la columna equivalente.
- `ID_QUOTA_SOCIAL`, `ID_TARIFA_SOCIAL`, `IND_SERVEI_SOCIAL` e `IND_POB_ENERG`: indicadores de vulnerabilidad o protección social.
- `TIP_FACT_ENV` y `NUM_COMPTE_IBAN`: datos de emisión y cobro que también se propagan a la factura.

`FACT_RESUM.POLISSA_SUBM` debe referenciar siempre una póliza existente en esta tabla.

### 4.9. SUBMIN_IAE

Relaciona suministros con epígrafes IAE. El CSV disponible es:

```text
submin_iae.csv
```

Depende de `SUBMIN_SERVEI` y `EPIGRAF_IAE`.

Un suministro puede tener más de un epígrafe. Para calcular el consumo industrial se utiliza el epígrafe principal de sección `I`. Los epígrafes secundarios de sección `S` se utilizan para enriquecer conceptos, pero no sustituyen al epígrafe industrial principal.

### 4.10. PADRO_TRR

Contiene el padrón de tasa de residuos. El CSV disponible es:

```text
padro_trr.csv
```

Depende de `SUBMIN_SERVEI` y, cuando se informa IAE, de `EPIGRAF_IAE`.

Campos relevantes:

- `POLISSA_SUBM`: suministro al que se aplica.
- `TS_PADRO_TRR`: fecha de alta o versión del padrón.
- `NOMB_HABIT_SUBM`: número de habitantes utilizado para el cálculo.
- `CONSUM_MES_BASE` y `CONSUM_MIG_DIA`: referencias de consumo.
- `TIP_QUOTA_TRR`: tipo de cuota.
- `PERC_BONIF_TRR`: porcentaje de bonificación.

### 4.11. PADRO_TAMGREM

Contiene la información de TAMGREM para actividades industriales. El CSV disponible es:

```text
padro_tamgrem.csv
```

Depende de `SUBMIN_SERVEI` y `EPIGRAF_IAE`.

Campos relevantes:

- `POLISSA_SUBM`.
- `TS_PADRO_TAMGREM` y `TS_ALTA`, que determinan desde cuándo aplica.
- `TIP_QUOTA_TAMGREM`.
- `IMP_CUOTA`.
- `SUPERFICIE_REAL` y `SUPERFICIE_POND`.
- `PERC_BONIF_TAMGREM`.
- `SECCIO` y `EPIGRAF_IAE`.

Cuando exista un registro vigente, el concepto `TAM` se incluye en `FACT_CONCEPTE`. No se incluye TAMGREM en suministros domésticos que no figuren en este padrón.

### 4.12. HIST_SS_PE

Contiene los periodos de vulnerabilidad social o pobreza energética. El CSV disponible es:

```text
hist_ss_pe.csv
```

Depende de `SUBMIN_SERVEI`.

Los campos clave son:

```text
POLISSA_SUBM
TIP_COLECTIVO
DATA_INI_IND
DATA_FIN_IND
```

Una factura se considera vulnerable cuando su periodo o fecha final se encuentra dentro de un intervalo activo. Las pólizas identificadas son `S000000021`, `S000000034`, `S000000058` y `S000000069`, pero se respetan exactamente sus distintas vigencias. `S000000058` y `S000000069` tienen más de un periodo y, por tanto, no se marcan como vulnerables durante los intervalos intermedios sin cobertura.

Durante la vigencia de vulnerabilidad se aplica:

- reducción del 50 % sobre el canon social aplicable;
- reducción del 30 % sobre TRR;
- utilización de los conceptos catalogados de bonificación cuando se representen en `FACT_CONCEPTE`, principalmente `BSA`, `BSQ` o `BOS`, según la naturaleza de la bonificación.

### 4.13. SERVEI_EQ_CI

Es la tabla de equipamiento contra incendios. El CSV disponible es:

```text
servei_eq_ci.csv
```

Solo contiene los suministros CI `S000000095` a `S000000100`.

Campos clave:

```text
NOMB_BOQUES_25
NOMB_BOQUES_45
NOMB_BOQUES_70
NOMB_BOQUES_100
NOMB_SPRINCKLERS
```

Los CI nunca generan consumo de agua facturado en m³. Su importe se calcula multiplicando las unidades de cada equipo por las tarifas `CI` de `TARIFA_FACTURACIO`:

```text
BOCA_25    1,00 EUR/unidad
BOCA_45    2,00 EUR/unidad
BOCA_70    4,00 EUR/unidad
BOCA_100   7,00 EUR/unidad
SPRINKLER  0,15 EUR/unidad
```

En `FACT_CONCEPTE` se usan los códigos reales:

```text
B25
B45
B70
B10
SPR
```

El IVA de estos conceptos debe representarse mediante `IVN`, que en el catálogo se define como IVA normal para bocas.

### 4.14. SERVEI_FACTURAR

Contiene el calendario efectivo de servicios CI a facturar. El CSV disponible es:

```text
servei_facturar.csv
```

En este piloto la tabla es exclusiva de servicios CI. `CALCUL_CONSUM_SERV = 'CI'` no significa que exista consumo medido. La tabla informa las fechas finales de facturación y las cantidades de equipos facturables para cada periodo.

Para los suministros CI se respeta exactamente cada fila de esta tabla:

- una fila de `SERVEI_FACTURAR` equivale a una factura CI;
- `DATA_FIN_FACT` será la fecha final de factura;
- `DIES_CONSUM_SERV` se utiliza para determinar el periodo inicial;
- las cantidades `NOMB_BOQ_*_SERV` y `NOMB_SPRINCK_SERV` prevalecen para la factura concreta;

### 4.15. CONVENI_FRAU

Contiene los suministros considerados fraudulentos. El CSV disponible es:

```text
conveni_frau.csv
```

La clave primaria es `POLISSA_SUBM`. En los datos actuales aparecen:

```text
S000000023 desde 2024-06-18
S000000091 desde 2025-01-22
```

La regla funcional es que un suministro se considera fraudulento desde `DATA_CREA_C_FRA` mientras permanezca en la tabla. Una factura anterior a esa fecha no se identifica como factura posterior al fraude. Aunque `FACT_RECUP` queda fuera del alcance actual, la condición de fraude se refleja mediante consumos anómalos y mediante estados o observaciones coherentes.

### 4.16. FACT_RESUM

El CSV disponible es:

```text
FACT_RESUM.csv
```

#### Calendario para suministros domésticos e industriales

La periodicidad de facturación es mensual.

Ningún suministro del piloto tiene fecha de alta anterior al 1 de enero de 2020 (`DATA_ALT_SUBM_SERV >= '2020-01-01'` en todos los casos). Por tanto, la primera factura de cada suministro se genera a partir de su fecha de alta real, no desde una fecha genérica de inicio del histórico.

Para suministros dados de alta después del inicio del histórico:

- no se crea ningún periodo anterior a `DATA_ALT_SUBM_SERV`;
- el ciclo mensual es 1, 11 o 21;
- la primera factura es la primera fecha de ciclo posterior o igual a la fecha de alta;
- `DATA_INI_FACT` es la fecha de alta para la primera factura y, para las siguientes, el día posterior al final del periodo anterior;
- `DATA_FIN_FACT` es la fecha de ciclo correspondiente;
- si existe una baja, el último periodo termina en `DATA_RES_SUBM_SERV`;
- no se generan facturas posteriores a la baja.

Si un suministro estaba activo antes del 1 de enero de 2020, la primera factura del histórico será la correspondiente al ciclo de enero de 2020.

#### Calendario para CI

Para `TIP_SUBM_SERV = 'C'`, no se calcula calendario 1/11/21. Se utiliza exclusivamente `SERVEI_FACTURAR`.

Cada fila de `servei_facturar.csv` genera una factura con:

```text
DATA_FIN_FACT = SERVEI_FACTURAR.DATA_FIN_FACT
DATA_INI_FACT = DATA_FIN_FACT - DIES_CONSUM_SERV + 1 día
CONSUMO = 0 m³
```

#### Numeración

La clave de factura sigue este modelo:

```text
ID_EMPRESA = valor municipal o 'AB' según maestro
ANY_FACTURA = año de DATA_FIN_FACT, con cuatro dígitos
NUM_FACTURA = secuencial dentro de cada año
```

#### Consumo doméstico

El consumo es variable y creíble, no fijo.

Base mensual orientativa:

```text
1 habitante  -> 10 m³
2 habitantes -> 14 m³
3 habitantes -> 18 m³
4 habitantes -> 22 m³
5 habitantes -> 28 m³
6 habitantes -> 35 m³
```

Se utiliza el número de habitantes vigente de `PADRO_TRR` y, si no existe, el de `SUBMIN_SERVEI`.

A la base se aplica:

- una variación por suministro y periodo de aproximadamente ±10 %;
- aumento progresivo hacia el verano;
- reducción en invierno;
- agosto es una excepción: una parte significativa de los clientes reduce el consumo por vacaciones, mientras otra parte mantiene un consumo alto por calor.

Como referencia estacional:

```text
Enero y febrero: reducción aproximada del 5 %
Mayo y junio: crecimiento moderado
Julio: incremento aproximado del 10 %
Agosto: incremento térmico, combinado con reducción vacacional para parte de los clientes
Septiembre: incremento aproximado del 5 %
Octubre a diciembre: descenso progresivo
```

#### Consumo industrial

El consumo industrial es habitualmente superior al doméstico y depende del epígrafe industrial principal:

```text
4101 -> base 120 m³/mes
4102 -> base 150 m³/mes
4103 -> base 180 m³/mes
4104 -> base 200 m³/mes
4105 -> base 240 m³/mes
4106 -> base 300 m³/mes
```

Se aplica una variación aproximada de ±15 % por periodo. También se aplica estacionalidad, pero con menor intensidad que en domésticos salvo actividades especialmente sensibles al calor.

#### Fraude

Los suministros de `CONVENI_FRAU` muestran comportamientos anómalos después de `DATA_CREA_C_FRA`. Se introducen varios periodos con incrementos de consumo de entre 1,8 y 2,5 veces sobre la base esperada. Antes de la fecha de fraude se comportan como un suministro normal de su categoría.

#### Vulnerabilidad

La factura identifica y aplica las condiciones sociales solo cuando `DATA_FIN_FACT` está dentro de una vigencia de `HIST_SS_PE`. Las bonificaciones reducen el importe correspondiente, pero no modifican artificialmente el consumo físico.

#### Bloques de consumo

Los m³ se distribuiyen en `M3_BLOC1` a `M3_BLOC5` utilizando los límites de `TARIFA_FACTURACIO`. La suma coincide con el consumo total del periodo:

```text
CONSUMO_TOTAL = M3_BLOC1 + M3_BLOC2 + M3_BLOC3 + M3_BLOC4 + M3_BLOC5
```

Para CI todos los bloques son cero.

#### Importe total

`IMP_TOTAL_FACT` es exactamente igual a la suma de `FACT_CONCEPTE.IMP_CONCEPTE` de la factura. Se establece una convención única respecto al IVA: las líneas de concepto incluyen tanto bases como líneas de IVA e `IMP_TOTAL_FACT` es la suma final de todas las líneas, incluidas bonificaciones negativas.

### 6.2. FACT_AIGUA

El CSV disponible es:

```text
FACT_AIGUA.csv
```

Se genera una fila por cada factura que incluye facturación de agua ordinaria. Para servicios CI se genera una fila con valores de agua a cero o no se crea `FACT_AIGUA` y se mantiene la facturación CI exclusivamente en `FACT_CONCEPTE`.

La fila reutiliza:

```text
NUM_PARTICIO
ID_EMPRESA
ANY_FACTURA
NUM_FACTURA
```

Los campos de precios por bloque proceden de `TARIFA_FACTURACIO`:

```text
PREU_M3_BLOC1_FACT = AIGUA/BLOC1
PREU_M3_BLOC2_FACT = AIGUA/BLOC2
PREU_M3_BLOC3_FACT = AIGUA/BLOC3
PREU_M3_BLOC4_FACT = AIGUA/BLOC4
PREU_M3_BLOC5_FACT = AIGUA/BLOC5
```

Los importes se calculan como:

```text
IMP_BLOCn = M3_BLOCn × PREU_M3_BLOCn_FACT
```

Los precios del canon se seleccionan según la vigencia de la factura. Desde 2024 se utiliza la familia nueva de `CANON_AIGUA`. Los conceptos sociales reducen el canon según la vigencia de vulnerabilidad.

`PERCENT_IVA_FACT` es el porcentaje `IVA/AIGUA` vigente, actualmente 10 %. `BASE_IVA` e `IMP_IVA` cuadran matemáticamente.

Las demás columnas obligatorias del DDL que no corresponden a un concepto aplicado se informan con cero, espacio o valor controlado, respetando sus tipos y restricciones `NOT NULL`. No se dejan columnas obligatorias sin valor.

`FACT_AIGUA` no contiene una columna `NUM_CONCEPTE`. Los códigos de concepto se registran en `FACT_CONCEPTE`; `FACT_AIGUA` representa el desglose cuantitativo y económico específico del agua.

### 6.3. FACT_CONCEPTE

El CSV disponible es:

```text
FACT_CONCEPTE.csv
```

Esta tabla contiene las líneas de conceptos asociadas a una factura de `FACT_RESUM`. Cada línea utiliza un `NUM_CONCEPTE` existente en `CODIFICACIONS` con `TIP_CODI = 'F25'`.

#### Conceptos domésticos

Los conceptos catalogados que pueden aparecer son:

```text
CA1  Canon de agua doméstico, tramo 1
CA2  Canon de agua doméstico, tramo 2
CA6  Canon de agua doméstico, tramo 3
CA7  Canon de agua doméstico, tramo 4
CA5  IVA del canon de agua
CL1  Alcantarillado, tramo 1
CL2  Alcantarillado, tramo 2
CON  Conservación de contador, cuando aplique
BSA  Bonificación social de agua, cuando aplique
BSQ  Bonificación social de cuota, cuando aplique
BOS  Bonificación de cuota social, cuando aplique
```

Los conceptos `CA1`, `CA2`, `CA6` y `CA7` son de canon, no deben confundirse con los cinco bloques de precio del suministro de agua de `FACT_AIGUA`.

#### Conceptos industriales

Los principales conceptos catalogados son:

```text
CA3  Canon industrial, gravamen general
CA4  Canon industrial, gravamen específico
CA5  IVA del canon
TAM  TAMGREM, cuando exista padrón vigente
CL1  Alcantarillado, tramo 1, si aplica
CL2  Alcantarillado, tramo 2, si aplica
CON  Conservación de contador, si aplica
```

`TAM` solo aparece si el suministro tiene registro vigente en `PADRO_TAMGREM`. El importe procede de `IMP_CUOTA` vigente o de la tarifa TAMGREM compatible con la categoría.

#### Conceptos CI

Los CI utilizan exclusivamente los conceptos asociados a equipos presentes en el periodo:

```text
B25  Bocas de 25
B45  Bocas de 45
B70  Bocas de 70
B10  Bocas de 100
SPR  Sprinklers
IVN  IVA normal para bocas
```

No se incluyen conceptos de consumo de agua ni canon por m³ en una factura CI.

#### Conceptos de vulnerabilidad

Las bonificaciones se representan como líneas negativas usando códigos existentes:

```text
BSA  Bonificación social de agua
BSQ  Bonificación social de cuota
BOS  Bonificación de cuota social
```

La suma de bonificaciones no puede reducir el total por debajo de cero.

#### Campos económicos

Para cada línea:

```text
BASE_CONCEPTE = cantidad o base de cálculo
PREU_CONCEPTE = precio unitario o porcentaje aplicable
IMP_CONCEPTE = importe final de la línea
IVA_APLICAT_CONC = porcentaje de IVA aplicable
```

Si `PREU_CONCEPTE` representa un porcentaje, queda claro en `TIP_TAXA_CONCEP` y en la observación. Si representa un precio por unidad, `BASE_CONCEPTE × PREU_CONCEPTE` cuadra con `IMP_CONCEPTE`, salvo redondeos a dos decimales.

La regla principal de validación es:

```text
Para cada factura:
FACT_RESUM.IMP_TOTAL_FACT
=
SUM(FACT_CONCEPTE.IMP_CONCEPTE)
```

### 6.4. SITUACIO_FACT

El CSV disponible es:

```text
SITUACIO_FACT.csv
```

Existe al menos una situación por factura. Para disponer en los dashboards de Power BI de las perspectivas de facturación bruta, fin de mes y estado actual, una parte de las facturas tiene más de una transición de estado.

El campo `TIP_SIT_FACT` utiliza exclusivamente códigos existentes en la familia `R01` de `CODIFICACIONS`.

Distribución orientativa del estado actual:

```text
80 % código 03, cobrada
10 % código 01, emitida
4 % código 04, devuelta
3 % código 24, reclamada
2 % código 20, aplazada
1 % códigos 05, 06, 07 o 34, cancelada o anulada
```

Las facturas antiguas estan mayoritariamente cobradas. Las facturas más recientes pueden permanecer emitidas, cargadas, reclamadas o pendientes.

Cuando una factura es anulada o cancelada y sustituida por otra, la factura original conserva su fila de `FACT_RESUM`, pero su estado actual es de anulación o cancelación. La factura sustituta es una factura distinta con nueva clave y estado ordinario. Esto permite que la perspectiva bruta incluya ambas y la perspectiva de estado actual excluya la anulada.

`MOM_SIT_FACT` es posterior a `DATA_EMISS_FACT` y las transiciones están ordenadas cronológicamente.

## 5. Arquitectura

La estructura en capas del modelo de datos será la siguiente:

raw_sicab
    -> l4_fact (bronze / staging en dbt)
        -> silver_fact (modelo estándar del negocio de facturación)
        -> silver_edw (modelo corporativo Data Vault 2.0)
            -> gold_fact (modelo estrella para analítica / Power BI)

La diferenciación entre `silver_fact` y `silver_edw` es importante:

- `silver_fact`: capa de negocio para facturación, con modelado estándar y prefijo `S_`.
- `silver_edw`: capa corporativa de entidades compartidas y reutilizables, con modelado Data Vault 2.0 y prefijos `EDW_H_`, `EDW_L_` y `EDW_S_` para hubs, links y satellites.
- `gold_fact`: capa final analítica, con modelo dimensional en estrella para consumo de BI.

Se mantiene el nombre de capa original en el proyecto y en dbt para evitar confusión con nomenclaturas ajenas: `raw_sicab`, `l4_fact`, `silver_fact`, `silver_edw` y `gold_fact`.

## 6. Ingesta

La ingestión se realizará mediante:

- Snowflake Stage
- COPY INTO

Los ficheros de origen serán los ficheros CSV con cabecera almacenados en la carpeta datos del proyecto.

## 7. Capa raw_sicab

- Una tabla en capa raw_sicab por fichero CSV.
- Nombre de tabla: raw_<nombre_fichero>
- Todos los campos de las tablas serán de tipo VARCHAR y tendrán nombres heredados de la cabecera del CSV.
- No se transformarán los datos.
- Se conservará la granularidad de origen.
- Los ficheros CSV de la carpeta `datos` son las fuentes de entrada del sistema y no se usarán como `seeds` de dbt.
- La carga se realizará en Snowflake con `COPY INTO` desde estos archivos CSV del sistema SICAB.
- Se incluirán campos de auditoría en cada tabla:
    * FECHA_EXTRACCION (TIMESTAMP_NTZ): Timestamp de extracción del registro. En nuestro piloto, timestamp del sistema en el instante de carga del registro en la tabla de la capa raw_sicab
    * SISTEMA_ORIGEN (VARCHAR(30)) : 'SICAB'

## 8. Capa l4_fact (Bronze)

- Una tabla en capa l4_fact por cada tabla de capa raw_sicab.
- Nombre de tabla: l4_<nombre_fichero>
- Campos tipados:
    * Conversión mediante TRY_TO_DATE.
    * Conversión mediante TRY_TO_NUMBER.
    * Conversión mediante TRY_TO_TIMESTAMP.
- Se incluirán campos de auditoría en cada tabla:
    * ID_CARGA (NUMBER): Secuencial numérico autogenerado. Por ejemplo: milisegundos de época del instante de inicio de carga del lote de datos, esto es, del instante de carga del primer registro de la primera entidad cargada para el lote en capa l4_fact. La meta es que todo el lote de datos cargado comparta un mismo ID. 
    * FECHA_EXTRACCION (TIMESTAMP_NTZ): Se heredará del registro original de la tabla correspondiente en capa raw_sicab.
    * FECHA_CARGA (TIMESTAMP_NTZ): Timestamp del sistema en el instante de carga del registro en esta tabla 
    * SISTEMA_ORIGEN (VARCHAR(30)) : Se heredará del registro original de la tabla correspondiente en capa raw_sicab.
    * TABLA_ORIGEN VARCHAR(50): Será el nombre de la tabla que contiene el registro original en capa raw_sicab 
- El modelo final obtenido por transformación de raw_sicab a l4_fact debe coincidir con el existente en ddl/DDL_AGUA_CLARA.sql.

## 9. Capa silver_edw

Capa Silver corporativa, compuesta por entidades que incluyen datos comunes a distintos data marts, con estructura Data Vault 2.0 y siguiente nomenclatura interna:
- `EDW_H_` para hubs
- `EDW_L_` para links
- `EDW_S_` para satellites

Se autogenerarán claves hash SHA2.

Se crearán los pares de tablas hub/satellite por cada una de las tablas siguientes: `l4_carrer`, `l4_dte_municipal`, `l4_epigraf_iae`, `l4_finca`, `l4_municipi_sgab`, `l4_ramal`, `l4_submin_iae`, `l4_submin_servei` y `l4_servei_eq_ci`. Por otro lado, a partir de los códigos comunes de la tabla `l4_codificacions` (TIP_CODI `THL`, `TSS` y `US`) se crearán los pares de tablas hub/satellite por tipo de código: `EDW_H_TIPO_VIVIENDA / EDW_S_TIPO_VIVIENDA` para `TIP_CODI='THL'`, `EDW_H_TIPO_SUMINISTRO / EDW_S_TIPO_SUMINISTRO` para `TIP_CODI='TSS'` y `EDW_H_TIPO_USO_AGUA / EDW_S_TIPO_USO_AGUA` para `TIP_CODI='US'`. Además, se crearán tantos links como sean necesarios entre entidades de la capa silver_edw, a partir de las claves foráneas involucradas en las entidades de la capa `l4_fact` que las alimenten.

Este modelo se incorpora en la capa `silver_edw` del proyecto, manteniendo el nombre de la capa original del dominio y no sustituyéndolo por otra nomenclatura de dbt.

- Se incluirán campos de auditoría en cada tabla:
    * ID_CARGA (NUMBER): Se heredará del registro original de la tabla correspondiente en capa l4_fact 
    * FECHA_EXTRACCION (TIMESTAMP_NTZ): Se heredará del registro original de la tabla correspondiente en capa l4_fact.
    * FECHA_CARGA (TIMESTAMP_NTZ): Timestamp del sistema en el instante de carga del registro en esta tabla
    * SISTEMA_ORIGEN (VARCHAR(30)) : Se heredará del registro original de la tabla correspondiente en capa l4_fact.
    * TABLA_ORIGEN VARCHAR(50): Será el nombre de la tabla que contiene el registro original en capa l4_fact. Si hay más de una tabla tabla1/tabla2...

## 10. Capa silver_fact

Entidades con datos específicos del data mart de facturación. Con un modelado estándar, se alimenta con las tablas `l4_fact` que no se incorporan a `silver_edw`.

Principales tablas:
- La nueva tabla `S_FACTURA_LINEA` es el eje central del modelo de negocio, representando cada registro una línea o concepto facturado. Incorpora datos de:
    * `l4_fact_resum` / `l4_fact_aigua` para consumos de agua
    * `l4_fact_resum` / `l4_fact_concepte` para resto de conceptos facturados
Por tanto, la contribución de `l4_fact_resum`, `l4_fact_aigua` y `l4_fact_concepte` a la capa `silver_fact` se limita a `S_FACTURA_LINEA`.

- `S_FACTURA_SITUACION_HIST`, con la historia de los estados de factura, alimentada con `l4_situacio_fact`

- `S_CONCEPTO`, con los códigos de la tabla `l4_codificacions` para `TIP_CODI='F25'`

- `S_SITUACION_FACTURA`, con los códigos de la tabla `l4_codificacions` para `TIP_CODI='R01'`

- Cualquier otra tabla de `l4_fact` no incorporada a `silver_edw` ni mencionada ya en este apartado.

- Se incluirán campos de auditoría en cada tabla:
    * ID_CARGA (NUMBER): Se heredará del registro original de la tabla correspondiente en capa l4_fact 
    * FECHA_EXTRACCION (TIMESTAMP_NTZ): Se heredará del registro original de la tabla correspondiente en capa l4_fact.
    * FECHA_CARGA (TIMESTAMP_NTZ): Timestamp del sistema en el instante de carga del registro en esta tabla
    * SISTEMA_ORIGEN (VARCHAR(30)) : Se heredará del registro original de la tabla correspondiente en capa l4_fact.
    * TABLA_ORIGEN VARCHAR(50): Será el nombre de la tabla que contiene el registro original en capa l4_fact. Si hay más de una tabla tabla1/tabla2...

La capa `silver_fact` debe considerarse un dominio de negocio y no un Data Vault; es decir, es un modelo estándar para consumo de facturación y no sustituye a `silver_edw`, sino que la complementa.

## 11. Capa gold_fact

Modelo estrella para Power BI.

Siendo g_h_factura_linea (obtenida directamente de s_factura_linea) y g_h_factura_situacion_hist (obtenida directamente de s_factura_situacion_hist) las tablas de hechos.

Construyéndose tantas tablas de dimensiones, con el prefijo "g_d_", como sean necesarias a partir del resto de tablas silver_edw y silver_fact y sumándose a estas una tabla para dimension temporal.

- Se incluirán campos de auditoría en cada tabla:
    * ID_CARGA (NUMBER): Se heredará del registro original de la tabla correspondiente en capa silver_fact o silver_edw
    * FECHA_EXTRACCION (TIMESTAMP_NTZ): Se heredará del registro original de la tabla correspondiente en capa silver_fact o silver_edw.
    * FECHA_CARGA (TIMESTAMP_NTZ): Timestamp del sistema en el instante de carga del registro en esta tabla
    * SISTEMA_ORIGEN (VARCHAR(30)) : Se heredará del registro original de la tabla correspondiente en capa silver_fact o silver_edw.
    * TABLA_ORIGEN VARCHAR(50): Será el nombre de la tabla que contiene el registro original en capa silver_fact o silver_edw. Si hay más de una tabla tabla1/tabla2...

## 12. Convenciones dbt
Se añadirán los siguientes tags por si se desean ejecutar los trabajos por capas

- raw_sicab
- l4_fact
- silver_edw
- silver_fact
- gold_fact

Convención de prefijos de objetos:

- `silver_fact`: prefijo `S_` para objetos estándar del negocio
- `silver_edw`: prefijo `EDW_H_` / `EDW_L_` / `EDW_S_` para objetos Data Vault 2.0
- `gold_fact`: prefijo `g_d_` para tablas de dimensiones y `g_h_` para tablas de hechos

Se mantienen los nombres de la capa del proyecto: `l4_fact`, `silver_fact`, `silver_edw` y `gold_fact`.

## 13. Validaciones dbt y ejecución por capa

La validación y la documentación de cada capa forman parte obligatoria de la ejecución de esa misma capa y no se dejan para el final del proyecto.

Regla de ejecución por capa:
1. Modelado de la capa.
2. Tests de calidad y consistencia de la capa.
3. Documentación dbt de la capa.
4. Validación de coherencia frente a la capa anterior y a la siguiente dependiente.

Esto aplica a:
- raw_sicab
- l4_fact
- silver_edw
- silver_fact
- gold_fact

Criterio de cierre de cada fase:
- la capa compila correctamente;
- sus tests pasan;
- su documentación dbt está actualizada;
- la salida es coherente con la capa anterior y reutilizable por la siguiente sin ambigüedad.

### raw_sicab
- Calidad técnica: Not Null, Unique, Accepted Values (solo casos obvios como S/N, 0/1, ...)
- Frescura origen: calculado a partir de FECHA_EXTRACCION. Error antigüedad > 15 días; aviso antigüedad > 7 días.
- Tipo de dato esperado (basado en la transformación del tipo de campo en el paso a la capa l4_fact).

### l4_fact
- Calidad técnica: Not Null, Unique.
- Integridad referencial basada en claves foráneas.
- Conciliación entre capas: registros esperados (raw_sicab) vs cargados (l4_fact).

### silver_edw / silver_fact
- Integridad referencial basada en claves foráneas para silver_fact e integridad Data Vault (Hub-Link-Satellite) para silver_edw.
- Calidad de datos: valores huérfanos, códigos inexistentes, ...
- Conciliación entre capas: registros esperados (l4_fact) vs cargados (silver_edw o silver_fact).

### gold_fact
- Integridad dimensional (Hecho-Dimensión).
- Conciliación entre capas: registros esperados (silver_edw o silver_fact) vs cargados (gold_fact).

## 14. Documentación dbt

La documentación es obligatoria dentro de la misma fase de construcción de cada capa.

Debe incluir:
- descripciones de tablas y campos según la función descrita en la capa;
- identificación de campos de clave primaria;
- identificación de campos referenciados (claves foráneas);
- relación funcional con la capa anterior;
- reglas de negocio o validaciones que la capa debe cumplir.

Esto permite que cada capa sea autocontenida, verificable y reutilizable al mismo tiempo que se genera.

## 15. Entornos
Se considerarán dos únicos entornos: Desarrollo y Producción

En Desarrollo, las compilaciones o ejecuciones del proyecto a nivel de desarrollador no deben afectar al resto de desarroladores, consolidándose, para ello, en el almacen de datos en esquemas personalizados por desarrollador: '[schema en profiles.yml]' + '_' + 'schema de capa en dbt_project.yml'. Para despliegues oficiales en Desarrollo y Producción el prefijo '[schema en profiles.yml]' + '_' debe obviarse.

## 16. Normas para generación automática

Cuando se reciba un CSV, la generación automática debe seguir la misma secuencia por capa y no puede cerrar una fase sin haber ejecutado previamente:

1. Modelado de la capa.
2. Tests de calidad y consistencia de la capa.
3. Documentación dbt de la capa.
4. Validación de coherencia frente a la capa anterior y a la siguiente dependiente.

Por cada CSV de la carpeta datos se aplicará esta secuencia:

1. Generar CREATE TABLE raw_sicab.
2. Generar COPY INTO.
3. Generar source.yml.
4. Generar modelo bronze (`l4_fact`) con sus tests de calidad.
5. Generar documentación dbt de la capa `l4_fact`.
6. Generar modelo `silver_fact` estándar del dominio con sus tests y su documentación.
7. Generar modelo `silver_edw` Data Vault 2.0 para entidades compartidas con sus tests y su documentación.
8. Generar modelo `gold_fact` dimensional para Power BI con sus tests y su documentación.
9. Validar coherencia entre capas antes de continuar a la siguiente fase.
10. Se tendrán en cuenta las consideraciones sobre los esquemas realizadas en el punto "15. Entornos".

Regla de cierre por capa:
- la capa compila correctamente;
- sus tests pasan;
- su documentación dbt está actualizada;
- la salida es coherente con la capa anterior y reutilizable por la siguiente sin ambigüedad.

Esto aplica a:
- raw_sicab
- l4_fact
- silver_edw
- silver_fact
- gold_fact

## 17. Alcance y exclusiones del piloto

En este proyecto se está trabajando con un alcance funcional concreto y no con la totalidad del universo de la facturación del sistema SICAB.

Se consideran dentro del alcance:
- fuentes crudas del piloto,
- capa `raw_sicab`,
- capa `l4_fact` conforme a `DDL_AGUA_CLARA.sql`,
- modelos `silver_fact`, `silver_edw`, `gold_fact` del dominio de Agua Clara,
- validación y documentación del flujo de transformación.

Se excluyen del alcance actual:
- `L4_FACT_REGUL`
- `L4_FACT_RECUP`
- referencias y transformaciones asociadas a `FACT_REGUL` y `FACT_RECUP`

La tabla `L4_SITUACIO_FACT` sí forma parte del alcance porque es una entidad relevante del flujo de estados de factura y servirá para la capa de negocio.

La relación entre sistemas y capas queda así:
- `SITUACIO_FACT` es la fuente del sistema SICAB.
- `L4_SITUACIO_FACT` es la tabla bronze del entorno Agua Clara.
- `S_FACTURA_SITUACION_HIST` es el modelo de negocio en `silver_fact`.

## 18. Resumen ejecutivo de arquitectura

La estructura final del proyecto es la siguiente:

- `raw_sicab`: datos sin procesar desde archivos CSV.
- `l4_fact`: capa bronze, tipada, validada y alineada con `DDL_AGUA_CLARA.sql`.
- `silver_fact`: modelo estándar del dominio de facturación, con prefijo `S_`.
- `silver_edw`: modelo Data Vault 2.0 para entidades corporativas compartidas, con prefijos `EDW_H_`, `EDW_L_`, `EDW_S_`.
- `gold_fact`: modelo dimensional estrella para Power BI.

Con esta arquitectura, los datos fluyen de origen a analítica de forma consistente, mantenible y trazable, y se respetan tanto las reglas de negocio como la gobernanza técnica de dbt y Snowflake.
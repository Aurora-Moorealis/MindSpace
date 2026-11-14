# Spec Delta

## Purpose

Define el contrato de datos de los eventos de la partida: arquetipos, targets, intensidades, ventanas, solapamiento, retraso y procedencia, para que el scheduler y la UI futuros consuman filas editables sin inventar reglas.

## ADDED Requirements

### Requirement: Registro de eventos con una fila por archivo

El registro SHALL exponer un índice de eventos y una fila por archivo. Cada fila MUST tener un `id` único en snake_case y MUST declarar su procedencia. Las filas con `real_data: false` MAY dejar `source` y `date_archived` vacíos; las filas con `real_data: true` MUST declarar una fuente y una fecha ISO-8601.

#### Scenario: Carga del registro inicial

- **WHEN** se carga el índice de eventos
- **THEN** contiene cinco filas y todos sus identificadores son únicos

#### Scenario: Fila sin procedencia

- **WHEN** una fila no declara procedencia
- **THEN** la validación la rechaza

#### Scenario: Fila placeholder

- **WHEN** una fila declara `real_data: false`
- **THEN** la validación acepta una fuente y una fecha vacías

### Requirement: Arquetipos y targets válidos

Cada fila SHALL declarar uno de los cinco arquetipos y un target compatible. Producción y consumo MUST apuntar a un recurso; avería MUST apuntar a una máquina; radiación MUST apuntar al pseudo-recurso `radiation`; corte de comunicaciones MUST no tener target.

#### Scenario: Caída de producción

- **WHEN** una fila es de tipo caída de producción
- **THEN** su target es `food`, `water`, `oxygen` o `energy`

#### Scenario: Avería de máquina

- **WHEN** una fila es de tipo avería
- **THEN** su target es una de las ocho máquinas del núcleo

#### Scenario: Ventana de radiación

- **WHEN** una fila es de tipo radiación
- **THEN** su target es `radiation`

#### Scenario: Target inválido

- **WHEN** una fila apunta a un target que no corresponde a su arquetipo
- **THEN** la validación la rechaza

### Requirement: Intensidad con signo e interpolación

Las intensidades SHALL almacenarse con signo: negativo para daño, consumo o caída; positivo para radiación. La fila MUST declarar `intensity_start`, `intensity_peak` e `intensity_end`. La intensidad SHALL interpolarse linealmente por tick: duración 1 usa el pico; duración 2 va de inicio a fin; duración 3 o más alcanza el pico en `duration_ticks / 2`.

#### Scenario: Ventana de varios ticks

- **WHEN** una ventana dura seis ticks con inicio 0.2, pico 0.8 y fin 0.2
- **THEN** el primer tick vale 0.2, el tick central vale 0.8 y el último vale 0.2

#### Scenario: Evento de un tick

- **WHEN** una fila dura un solo tick
- **THEN** su intensidad es el pico

#### Scenario: Signo incorrecto

- **WHEN** una avería, caída o pico de consumo declara una intensidad positiva
- **THEN** la validación la rechaza

### Requirement: Ventana temporal

Cada fila SHALL declarar `onset_tick` absoluto y `duration_ticks`. `onset_tick` MUST ser mayor o igual que 0 y `duration_ticks` MUST ser mayor o igual que 1. La ventana activa SHALL ser `[onset_tick, onset_tick + duration_ticks)`. La ventana MUST terminar dentro de los 300 ticks de misión.

#### Scenario: Límites de la ventana

- **WHEN** una ventana empieza en el tick 3 y dura 6
- **THEN** está activa en los ticks 3 a 8 y deja de estarlo en el 9

#### Scenario: Duración inválida

- **WHEN** una fila declara duración 0 o negativa
- **THEN** la validación la rechaza

#### Scenario: Fin fuera de misión

- **WHEN** una fila termina después del tick 300
- **THEN** la validación la rechaza

### Requirement: Solapamiento con consentimiento mutuo

Cada fila SHALL declarar `overlap_policy`: `EXCLUSIVE`, `WHITELIST` o `ANY`. `EXCLUSIVE` MUST impedir cualquier solapamiento. `WHITELIST` MUST listar los identificadores permitidos en `overlap_with`. `ANY` MUST no restringir por su parte. Dos eventos solo SHALL solaparse cuando ambas filas lo acepten.

#### Scenario: Whitelist mutua

- **WHEN** dos filas se listan mutuamente en `overlap_with`
- **THEN** pueden solaparse

#### Scenario: Whitelist unilateral

- **WHEN** una fila lista a otra pero la otra no la lista
- **THEN** no pueden solaparse y la validación lo advierte

#### Scenario: Veto exclusivo

- **WHEN** una fila es `EXCLUSIVE`
- **THEN** no puede solaparse con ninguna otra

#### Scenario: Referencia desconocida

- **WHEN** `overlap_with` referencia un id que no existe
- **THEN** la validación la rechaza

### Requirement: Retraso declarado por fila

Cada fila SHALL declarar `delay_min_ticks` y `delay_max_ticks` para el retraso de cola cuando no pueda solaparse. Ambos MUST ser mayores o iguales que 0 y `delay_max_ticks` MUST ser mayor o igual que `delay_min_ticks`.

#### Scenario: Rango de retraso válido

- **WHEN** una fila declara un mínimo de 1 y un máximo de 3
- **THEN** la validación acepta el rango

#### Scenario: Rango invertido

- **WHEN** una fila declara un mínimo mayor que el máximo
- **THEN** la validación la rechaza

### Requirement: Corte de comunicaciones sin efecto numérico

Una fila de corte de comunicaciones SHALL tener target vacío e intensidades cero. El corte MUST quedar como dato para que la consola lo consuma después y MUST NOT bloquear el envío de informes.

#### Scenario: Corte declarado

- **WHEN** una fila es de tipo corte de comunicaciones
- **THEN** no tiene target y sus tres intensidades son cero

#### Scenario: Corte con daño

- **WHEN** una fila de corte declara una intensidad distinta de cero
- **THEN** la validación la rechaza

### Requirement: Validación headless del registro

El proyecto SHALL incluir un validador ejecutable en headless que cargue el registro real y compruebe identificadores, targets, signos, ventanas, solapamiento, interpolación y procedencia. El validador SHALL salir con código 0 cuando todo es válido y distinto de 0 cuando hay errores.

#### Scenario: Registro válido

- **WHEN** se ejecuta el validador sobre el registro inicial
- **THEN** termina con código 0 y sin errores

#### Scenario: Registro inválido

- **WHEN** una fila incumple una regla del contrato
- **THEN** el validador reporta el problema y termina con código distinto de 0

# Spec Delta

## MODIFIED Requirements

### Requirement: Contenido de la pantalla de entrada

La pantalla SHALL mostrar el título del juego, un subtítulo y las acciones de
iniciar partida y de abrir los ajustes.

#### Scenario: Presentación completa

- **WHEN** el jugador llega al menú
- **THEN** ve el título, el subtítulo y las dos acciones completas, sin recortes ni solapamientos entre ellas

### Requirement: Acción Iniciar juego

Al activar la acción de iniciar partida, el juego SHALL entrar en la siguiente
fase si esa escena existe. Si no existe, SHALL avisar y permanecer en el menú.

#### Scenario: El destino existe

- **WHEN** el jugador activa la acción de iniciar partida y la escena de destino está disponible
- **THEN** el juego cambia a esa escena

#### Scenario: El destino todavía no existe

- **WHEN** el jugador activa la acción de iniciar partida y la escena de destino no está disponible
- **THEN** aparece un aviso que lo explica y el menú sigue en pantalla

### Requirement: Acción Configuración

Al activar la acción de ajustes, el juego SHALL entrar en la pantalla de ajustes
si existe. Si no existe, SHALL avisar y permanecer en el menú.

#### Scenario: El destino existe

- **WHEN** el jugador activa la acción de ajustes y la pantalla de ajustes está disponible
- **THEN** el juego cambia a esa pantalla

#### Scenario: El destino todavía no existe

- **WHEN** el jugador activa la acción de ajustes y la pantalla de ajustes no está disponible
- **THEN** aparece un aviso que lo explica y el menú sigue en pantalla

### Requirement: Navegación sin ratón

Al abrirse el menú, el foco SHALL estar en la primera acción, para poder recorrer
todas las acciones solo con teclado.

#### Scenario: Foco inicial

- **WHEN** el jugador llega al menú
- **THEN** la acción de iniciar partida aparece enfocada y se puede cambiar de acción con el teclado

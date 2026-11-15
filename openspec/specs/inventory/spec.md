# inventory Specification

## Purpose
Define el inventario de la hotbar: cinco espacios, un objeto por espacio, el
movimiento de objetos de lugar por lugar y la selección del espacio activo.

## Requirements

### Requirement: Inventario de cinco espacios

El inventario SHALL tener exactamente cinco espacios numerados de 0 a 4 y cada
espacio SHALL contener como máximo un objeto. Los índices SHALL mantenerse
estables mientras el inventario exista.

#### Scenario: Inventario vacío al empezar

- **WHEN** empieza una partida nueva
- **THEN** los cinco espacios están vacíos y el espacio 0 está seleccionado

#### Scenario: Un solo objeto por espacio

- **WHEN** se coloca un objeto en un espacio que ya tenía otro
- **THEN** el espacio pasa a contener el objeto nuevo y el anterior deja de estar
  en él

### Requirement: Colocar y retirar objetos

El inventario SHALL permitir colocar un objeto en un espacio válido, retirarlo y
consultar qué objeto hay en cada espacio. Una operación sobre un índice fuera de
rango SHALL no modificar el inventario ni provocar un error. Cada cambio de
espacio SHALL notificarse con su índice y el objeto resultante.

#### Scenario: Colocar un objeto

- **WHEN** se coloca un objeto válido en un espacio vacío
- **THEN** el espacio contiene ese objeto y se notifica el cambio de ese índice

#### Scenario: Índice fuera de rango

- **WHEN** se intenta colocar o retirar un objeto usando un índice menor que 0 o
  mayor que 4
- **THEN** el inventario queda igual y la partida sigue

### Requirement: Mover objetos de lugar por lugar

El jugador SHALL poder mover un objeto de un espacio a otro de uno en uno. Al
recoger un objeto, su espacio de origen SHALL quedar vacío y el objeto SHALL
seguir en la mano del jugador; al colocarlo en otro espacio, el objeto anterior de
ese espacio, si lo había, SHALL pasar a la mano. El jugador SHALL poder devolver
el objeto a un hueco libre y SHALL poder intercambiar dos espacios directamente.

#### Scenario: Recoger y colocar

- **WHEN** el jugador recoge el objeto del espacio 1 y hace clic en el espacio 3
- **THEN** el espacio 1 queda vacío y el espacio 3 contiene el objeto

#### Scenario: Intercambio

- **WHEN** el jugador coloca un objeto en un espacio que ya tiene otro
- **THEN** los objetos quedan intercambiados entre la mano y ese espacio

#### Scenario: Devolver a un hueco

- **WHEN** el jugador cancela con un objeto en la mano
- **THEN** el objeto vuelve a un espacio libre y la mano queda vacía

#### Scenario: Mover sin hueco libre

- **WHEN** el jugador intenta devolver el objeto y los cinco espacios están
  ocupados
- **THEN** el objeto permanece en la mano y no se pierde

### Requirement: Arrastrar y soltar

El jugador SHALL poder arrastrar el objeto de un espacio y soltarlo sobre otro
espacio. Si el destino está ocupado, los dos objetos SHALL intercambiarse. Si el
destino es el mismo espacio de origen, el inventario SHALL quedar igual.

#### Scenario: Arrastrar a un espacio vacío

- **WHEN** el jugador arrastra un objeto del espacio 2 al espacio 4 vacío
- **THEN** el espacio 2 queda vacío y el espacio 4 contiene el objeto

#### Scenario: Arrastrar sobre un espacio ocupado

- **WHEN** el jugador arrastra un objeto sobre un espacio que ya tiene otro
- **THEN** los dos objetos intercambian sus espacios

### Requirement: Selección del espacio activo

El inventario SHALL tener siempre un espacio activo. El jugador SHALL poder
cambiarlo con las teclas 1 a 5, con la rueda del ratón y haciendo clic en un
espacio vacío. Colocar un objeto SHALL activar el espacio de destino. La selección
SHALL notificarse solo cuando cambie.

#### Scenario: Elegir con el teclado

- **WHEN** el jugador pulsa la tecla 4
- **THEN** el espacio 4 pasa a ser el activo

#### Scenario: Recorrer con la rueda

- **WHEN** el jugador usa la rueda sobre el último espacio
- **THEN** la selección pasa al primer espacio sin salirse del rango

#### Scenario: Selección repetida

- **WHEN** el jugador selecciona el espacio que ya está activo
- **THEN** no se emite una notificación nueva

### Requirement: Objetos del inventario

Cada objeto SHALL tener un identificador no vacío, un nombre visible y,
opcionalmente, un icono. Un objeto con identificador vacío SHALL rechazarse. El
icono SHALL dibujarse sobre el espacio sin sustituir su marco.

#### Scenario: Objeto válido

- **WHEN** se coloca un objeto con identificador y nombre
- **THEN** el espacio lo muestra con su icono y su nombre sigue disponible para
  una consulta

#### Scenario: Objeto inválido

- **WHEN** se intenta colocar un objeto sin identificador
- **THEN** el inventario no cambia

### Requirement: Integración con la partida

La escena de HUD SHALL exponer su inventario para que el resto de la partida
pueda añadir objetos y consultar el espacio activo. Una partida nueva SHALL vaciar
el inventario. El inventario SHALL vivir mientras viva el HUD y no SHALL
persistirse entre partidas.

#### Scenario: Añadir un objeto desde la partida

- **WHEN** la partida pide añadir un objeto y queda un hueco libre
- **THEN** el objeto ocupa el primer hueco libre y la hotbar lo muestra

#### Scenario: Reinicio

- **WHEN** la partida se reinicia
- **THEN** los cinco espacios vuelven a estar vacíos y el espacio 0 queda activo

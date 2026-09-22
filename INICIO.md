# CENIZA NEÓN — primera sesión

Proyecto para Godot 4.x. No requiere plugins ni assets externos.

1. Abre Godot y pulsa **Importar** en el administrador de proyectos.
2. Selecciona `project.godot` en esta carpeta y abre el proyecto.
3. Presiona **F6** con `scenes/main.tscn` abierta, o **F5** para ejecutar el proyecto.
4. Muévete con A/D, flechas, stick izquierdo o cruceta del mando.
5. Detén la ejecución con F8 desde el editor.

## Qué aprender aquí

- **Escena:** `scenes/player.tscn` agrupa el personaje, su colisión y su cámara.
- **Nodo:** cada elemento del árbol tiene una responsabilidad. `CharacterBody2D` permite mover un cuerpo con colisiones.
- **Script:** `scripts/player.gd` define el movimiento. `_physics_process` se ejecuta a intervalos de física.
- **Input Map:** relaciona acciones como `move_left` con teclas y mando. En esta primera escena se configura al arrancar en `scripts/world.gd`.
- El escenario y la interfaz se crean desde `world.gd`; aparecerán en el árbol **Remoto** mientras ejecutas el juego.

## Primera práctica

Abre `scenes/player.tscn`, selecciona el nodo Player y cambia **Speed** en el Inspector de 150 a 220. Guarda y ejecuta. Compara qué velocidad te resulta cómoda y vuelve a ajustarla.

## Comprobación manual

- El personaje se apoya en el suelo y no lo atraviesa.
- Puedes caminar en ambos sentidos y detenerte al soltar el control.
- La cámara sigue al personaje; los extremos del mapa bloquean el paso.
- Las instrucciones permanecen en pantalla.
- Si tienes mando, comprueba stick y cruceta.

## Segunda práctica: ataque y vida

Ejecuta con F5 y acércate al blanco rosado a la derecha del núcleo. Mira hacia él y pulsa **J**, o el botón **X de Xbox / Cuadrado de PlayStation**. Cada pulsación hace un ataque; mantener el botón no repite golpes.

- El blanco tiene 100 de vida y cada golpe quita 25: cae con cuatro golpes.
- Desde lejos o mirando hacia el otro lado, el ataque falla.
- Hay 0,4 segundos de espera entre ataques. El destello amarillo muestra el alcance.
- El blanco reaparece tres segundos después de caer. Puedes atravesarlo: todavía es un blanco de práctica, sin contacto físico ni ataques propios.

En `player.tscn`, selecciona Player y cambia **Attack Damage** a 50. Guarda y comprueba que ahora cae con dos golpes. Vuelve a 25 al terminar. Conserva la velocidad que hayas elegido.

El método `attack()` comprueba alcance y aplica daño; `take_damage()` en `scripts/training_enemy.gd` actualiza la vida. Todavía no hay construcción ni guardado. El siguiente incremento será que el enemigo avance y ataque.

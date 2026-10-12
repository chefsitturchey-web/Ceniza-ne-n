# Animaciones del errante

El juego instancia `entities/enemies/errante.tscn` para los errantes. Su raíz tiene el script `entities/enemies/siege_enemy.gd`, que selecciona automáticamente las cinco animaciones de `AnimatedSprite2D`:

| Nombre exacto | Cuándo se utiliza |
|---|---|
| `reposo` | Espera entre acciones |
| `caminar` | Avance hacia la colonia |
| `ataque` | Anticipación y golpe |
| `daño` | Reacción a impactos fuera de la anticipación del ataque |
| `destruccion` | Muerte, antes de retirar el sprite |

Puedes editar los cuadros desde Sprite Frames; conserva los nombres y guarda con Ctrl+S. Reposo y caminar tienen bucle. Ataque, daño y destrucción se reproducen una vez. El código ajusta la velocidad visual del ataque al ciclo de combate existente (0,5 segundos de aviso y 1,1 de recuperación) y la reacción de daño a 0,32 segundos. Durante la anticipación, el impacto tiñe al enemigo sin ocultar el aviso de ataque.

Los PNG son de 48 × 48. El AnimatedSprite2D está centrado y desplazado a (0, -21), colocando la base visible de los pies en el suelo. Se usa filtro Nearest y reflejo horizontal automático. No hay que cambiar la escala del nodo raíz. El corredor utiliza `entities/enemies/corredor.tscn`, con el mismo controlador de combate y su animación `correr` configurada en `EnemyData`.

## Probar

Pulsa F5, espera al asedio y acércate a un errante. Comprueba que camine mirando hacia su objetivo, ataque cerca de ti, reaccione a los golpes y muestre la destrucción al morir. Puedes pausar con Esc: las animaciones también se detienen. Para previsualizar únicamente reposo, abre la escena Errante y pulsa F6.

Se ha conservado tu ajuste de `day_duration = 10` en `data/cycles/district.tres` para pruebas rápidas. Para una partida con tiempo de construcción, asigna `data/cycles/standard.tres` a `Cycle.config` en la escena principal.

Prueba automática: `godot --headless --path . --script res://tests/errante_animation_smoke.gd`.

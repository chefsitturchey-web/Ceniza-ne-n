# CENIZA NEÓN — prototipo de colonia y asedio

Abre `project.godot` con Godot 4 y pulsa F5. La configuración base tiene tres ciclos de 90 segundos de día, 10 de aviso y 60 de noche (unos ocho minutos). Este worktree conserva tu ajuste de pruebas: días de 10 segundos, unos cuatro minutos por partida. La noche se prolonga si quedan enemigos vivos. Sin guardado todavía.

## Controles

| Acción | Teclado | Mando Xbox |
|---|---|---|
| Mover | A/D o flechas | Stick izquierdo / cruceta |
| Atacar (puedes mantener) | J | X |
| Esquivar, cuesta 30 de resistencia | Espacio | A |
| Construir, reparar, reclutar o curar | Mantener E | Mantener Y |
| Sobrecargar tu frente | Q | LB |
| Pausar | Esc | Start |
| Reiniciar después del resultado | R | Select / Back |

PlayStation: X de Xbox corresponde a Cuadrado; A a Cruz; Y a Triángulo; LB a L1. El HUD de mando usa etiquetas Xbox.

## Primera partida

1. Empiezas con 90 de chatarra, un constructor y un recuperador. Los marcos vacíos a ambos lados son puntos de construcción.
2. Acércate a cada punto y mantén E: muralla 20, torreta 25. Las cuatro obras cuestan 90. El constructor las realiza automáticamente: encargar no significa completar instantáneamente.
3. El recuperador sale de día y deposita ocho unidades por viaje. En el centro, mantén E para contratar un segundo constructor y después un segundo recuperador, por 15 cada uno.
4. Al llegar el aviso, los recuperadores regresan. Los constructores evitan obras cercanas a enemigos. Puedes encargar reparaciones por ocho de chatarra, pero debes despejar la zona para que trabajen.
5. Durante la noche, consulta las amenazas de ambos lados, apoya la muralla más presionada y esquiva los ataques anunciados con un signo sobre el enemigo.
6. Q sobrecarga el lado donde estás: seis segundos de disparos y obras más rápidos, después dieciocho segundos de enfriamiento. Cada frente tiene su propio temporizador.
7. Sobrevive tres noches. Si te derrotan, reapareces a los cuatro segundos mientras la colonia sigue luchando. Si cae el núcleo, termina la partida.

En el centro puedes curarte de día con E. Al amanecer se restauran 40 puntos del núcleo, se cura al personaje y recibes 25 de chatarra. El dron cercano al personaje dispara automáticamente, con alcance y daño limitados.

## Alcance de esta entrega

- Dos enemigos: errante y corredor; ataque con aviso, vida, muerte y recompensa.
- Cuatro habitantes como máximo, con oficios automáticos y reserva individual de obras.
- Dos murallas, dos torretas, energía de capacidad fija (4), sobrecarga por frente.
- HUD de recursos, salud, resistencia, amenazas, obras y temporizadores.
- Pausa, victoria, derrota y reinicio completo.

Simplificaciones del prototipo: trabajadores sin daño ni selección de herramientas; chatarra en una bolsa común; generación eléctrica fija; torretas no son objetivo de enemigos; no hay progresión, guardado, jefes, sonido ni arte final. Al perder se reinicia toda la sesión, todavía no se restaura el inicio del día como propone el GDD. La dificultad necesita pruebas con jugadores.

Tus ajustes del personaje siguen en `entities/player/player.tscn`: velocidad 220 y daño 50. Los tiempos se editan en el Resource `config` del nodo `Cycle` en `levels/main.tscn`. Está asignado `data/cycles/district.tres` (10/10/60). Para disponer de 90 segundos de construcción, asigna `data/cycles/standard.tres` (90/10/60). Los controles y costos no han cambiado.

El corredor del asedio y los constructores ya utilizan sus escenas animadas. Para comprobarlo, encarga una obra con E y observa cómo el constructor camina y trabaja; durante la noche, cada tercer enemigo será un corredor animado. Jugador y recuperador conservan su dibujo provisional.

## Arte

La dirección visual y los prompts están en `docs/GUIA_ARTE.md`. Primero prepara un cuadro maestro del personaje, del errante y del corredor. No generes todas las animaciones hasta aprobar esos tres.

## Verificación técnica

Con el ejecutable de Godot desde esta carpeta:

```text
godot --headless --path . --import
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --script res://tests/combat_smoke.gd
godot --headless --path . --script res://tests/siege_smoke.gd
godot --headless --path . --script res://tests/session_simulation.gd
godot --headless --path . --script res://tests/session_simulation.gd -- --assist
```

Las simulaciones parten de defensas ya construidas. Sin apoyo, la colonia debe caer; con --assist, un jugador automatizado se desplaza, ataca, sobrecarga y encarga reparaciones durante el día. Esta segunda prueba no valida la construcción inicial ni sustituye la prueba de dificultad humana.

## Expedición al jefe (Distrito 1)

1. De día, ve a los extremos del mapa y destruye los dos **repetidores** enemigos (torres con luces rosas).
2. Al caer ambos llega el **tren blindado** a la estación, a la derecha del núcleo.
3. De día, mantén **E** en la estación para viajar a la arena de **El Recaudador** (vista cenital, movimiento en ocho direcciones).
4. Su escudo bloquea los golpes de frente. Esquiva su embestida: si choca contra una pared queda aturdido y su núcleo expuesto recibe doble daño.
5. Si pierdes, vuelves a la colonia en el mismo momento; si ganas, el Distrito 1 queda completado.

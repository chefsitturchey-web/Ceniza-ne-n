# CENIZA NEÓN — prototipo de colonia y asedio

Abre `project.godot` con Godot 4 y pulsa F5. El menú permite Nueva partida, Continuar y Opciones. La revisión del GDD usa 180 segundos de día, 20 de aviso y 90 de noche; los presets anteriores se conservan. Hay guardado al amanecer y recuperación diaria al perder el núcleo. Empieza por [la guía actual de Kingdom y progresión](docs/REVISION_GDD_KINGDOM_SURVIVORS.md).

La partida nueva comienza con una explicación que detiene el reloj hasta pulsar Comenzar. Las torretas ya apuntan y tienen retroceso; el Portador camina al norte/sur en la arena y el recuperador se anima al trabajar. Los objetivos de pantalla guían hasta el tren. El final del jefe completa esta demo y permite volver al menú. Detalles y comprobaciones en [PULIDO_JUGABLE.md](docs/PULIDO_JUGABLE.md).

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
| Silenciar música y efectos | M | — |

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

## Contenido jugable

- Cinco enemigos: errante, corredor, blindado, saltador y ariete; ataques con aviso, vida, muerte y recompensa.
- Cuatro habitantes como máximo, con oficios automáticos y reserva individual de obras.
- Dos murallas, dos torretas, energía de capacidad fija (4), sobrecarga por frente.
- HUD de recursos, salud, resistencia, amenazas, obras y temporizadores.
- Pausa, victoria, derrota y reinicio completo.
- Clínica a la izquierda del núcleo: cada seis máquinas derrotadas dan un punto; mantener E de día permite mejorar filo, dron o capacitor. Tres rangos por mejora. El mundo se pausa mientras eliges; Esc/Start cierra.
- En la pestaña Equipo hay tres módulos, dos ranuras, cinco niveles y pasivas. La última unidad de cada oleada entrega un núcleo para evolucionar un equipo de nivel cinco con su pasiva compatible.
- Sonidos de combate, música de trabajo por fases, ceniza ambiental y reflejos estilizados de luces y personajes.

Simplificaciones actuales: chatarra en una bolsa común, trabajadores económicos sin daño y torretas sin selección como objetivo enemigo. Ya hay herramientas, profesiones, generadores, experiencia con elecciones, tres zonas y tres jefes. Perder el núcleo conserva el último guardado diario en todas las colonias. Música, personajes y contenido final siguen pendientes de producción y equilibrio con jugadores.

Tus ajustes del personaje siguen en `entities/player/player.tscn`: velocidad 220 y daño 50. La revisión del GDD asigna `data/cycles/kingdom.tres` al nodo `Cycle`: 180 segundos de día, 20 de aviso y 90 de noche. Los presets anteriores `district.tres` (10/10/60) y `standard.tres` (90/10/60) se conservan.

Jugador, recuperador, constructor, errante y corredor utilizan sprites animados. Para comprobarlo, encarga una obra con E y observa cómo el constructor camina y trabaja. Blindado, saltador y ariete usan siluetas mecánicas propias animadas por piezas, con los sprites anteriores conservados como alternativa.

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
5. Si pierdes, vuelves a la colonia en el mismo momento. Si ganas, pulsa **Viajar a Fundición** para continuar con tus mejoras y habitantes.

## Fundición y Barrio inundado

La ruta disponible tiene tres distritos. Fundición añade rejillas nocturnas y Santa Caldera; Barrio inundado añade charcos y el Coro Sumergido. Cada zona tiene repetidores y estación propios. La victoria guarda la llegada al siguiente distrito antes de viajar, y **Continuar** en el menú recupera esa ruta.

Para probar sin recorrer la campaña, abre `levels/zones/foundry.tscn` o `flooded.tscn` y pulsa F6. Para practicar sus jefes, abre `levels/expedition/caldera_arena.tscn` o `choir_arena.tscn`. El Recaudador conserva su escena original. [Mecánicas y validación del bloque](docs/CAMPANA_Y_JEFES.md).

## Más estructuras y unidades

**Reglas actuales:** [guía del GDD, Kingdom y progresión](docs/REVISION_GDD_KINGDOM_SURVIVORS.md). Los edificios requieren constructores; las tropas, supervivientes y herramientas. F ordena avance/retirada. La experiencia se recoge y abre tres opciones al subir. Todas las colonias recuperan su guardado diario al perder el núcleo.

Los tres mapas tienen ahora 3200 unidades de ancho. Explora cajas de suministros y despliega de día, con E, cuarteles, puestos médicos, generadores y recicladoras. Los generadores dan energía a los fusileros y sanitarios; artilleros y saboteadores enemigos aparecen en las oleadas avanzadas.

Para ver las novedades rápidamente, abre **`levels/zones/expansion_playground.tscn` y pulsa F6**: defensas listas, presupuesto de práctica y tiempo para desplegar. Esa escena no guarda sobre tu partida. [Costes, funciones y controles](docs/EXPANSION_Y_UNIDADES.md).

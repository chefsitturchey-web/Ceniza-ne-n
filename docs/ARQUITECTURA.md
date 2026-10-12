# Arquitectura — fase 1

`levels/main.tscn` compone los nodos. `District` conecta referencias tipadas y señales al iniciar; no contiene reglas de partida. No hay autoload global ni búsquedas de padres. Cada sesión posee sus datos de ejecución; los Resources compartidos se tratan como configuración de solo lectura.

```text
District (composición y conexiones)
 ├─ CycleSystem ── phase_changed / dawn / victory_requested
 │    └─ SiegeDirector ← WaveData[] ← EnemyData → escena SiegeEnemy
 │                         spawned / reward_requested → ResourceBank
 ├─ ResourceBank ← pagos, depósitos y recompensas; reserva energía de obras
 ├─ ConstructionSystem ← StructureData[] → ConstructionSite + HealthComponent
 ├─ ColonySystem ← WorkerData → ColonyWorker (reserva una obra por constructor)
 ├─ InteractionSystem → curación, reclutamiento y órdenes de construcción
 ├─ OverloadSystem ── changed → aspecto de estructuras; bonus por frente
 ├─ DefenseSystem → torretas y dron → HurtboxComponent
 ├─ SessionController ← dawn / victory_requested; derrota, pausa y reinicio
 │    └─ frame_finished → DistrictView (fondo, dron y disparos)
 └─ HudPresenter ← notice_requested; updated(texto, ayuda, resultado)
      └─ ui/hud.tscn (solo recibe la señal y muestra etiquetas)

Player / SiegeEnemy / TrainingEnemy / ConstructionSite / ColonyCore
 └─ HealthComponent ── damaged / healed / died
Player → HitboxComponent → HurtboxComponent ── hit → receptor de daño
PlayerVisual / EnemyVisual / WorkerVisual → EntityVisual (interfaz común)
```

Los sistemas se actualizan en un orden explícito desde `SessionController`: sobrecarga, ciclo/oleada, trabajadores, defensas, interacción, disparos y HUD. Esto conserva el orden del prototipo, incluidas las simulaciones deterministas. Cada sistema tiene menos de 150 líneas. Las entidades mantienen su física en `_physics_process`; no se añaden colisiones que cambien los alcances originales.

La vida se limita y emite señales en `HealthComponent`. Curar no revive a un muerto: `reset()` es explícito para reaparición, construcción y preparación de pruebas. Los receptores conservan invulnerabilidad y tiempos propios. La muerte retira inmediatamente la amenaza y entrega una sola recompensa; el sprite puede seguir mostrando destrucción sin retrasar el amanecer.

Estados del jugador: `IDLE`, `MOVE`, `ATTACK`, `DODGE`, `DEAD`; los temporizadores determinan las transiciones y la esquiva tiene prioridad sobre el ataque. Estados del enemigo: `APPROACH`, `WINDUP`, `ATTACK`, `DEAD`. Las animaciones no disparan daño: el temporizador de anticipación sigue siendo la autoridad.

## Configuración conservada

- Base: `data/cycles/standard.tres`, 90/10/60 segundos, tres noches; amanecer +25 chatarra, +40 núcleo, vida del jugador a 100.
- Distrito activo: `data/cycles/district.tres`, **10/10/60**, conserva el ajuste previo de la escena.
- Jugador: `entities/player/player.tscn`, velocidad **220**, daño **50**.
- Oleadas: 12/16/20 enemigos, lados alternos desde la izquierda, corredor cada tercer enemigo; cadencia 1,8/1,4/1,0 s; +20 de vida por noche posterior a la primera.
- `WaveData.cadence` conserva `cadence_base - cadence_steps * cadence_decrement`. Mantener la operación original evita que el redondeo de un decimal serializado adelante un tick de simulación. Para una cadencia fija nueva puede usarse decremento cero.
- Grupos, capas y constantes compartidas: `core/game_rules.gd`. Costos, estadísticas y escenas: `data/`. Geometría provisional y colores permanecen junto a la presentación.

## Validación

`SaveSystem` pertenece a cada sesión, sin autoload. `District` llama a `SessionController.initialize()` una vez conectadas las referencias. La sesión carga `user://partida.json` (JSON, versión 1) o guarda el primer día; `phase_changed` guarda los siguientes días después de las recompensas de `dawn`. Victoria, derrota y reinicio eliminan el archivo. La carga valida el documento completo antes de aplicar cambios y reinicia el temporizador del día con la configuración existente. Conserva recursos, vida, estructuras, trabajos y carga de habitantes, además de posición y temporizadores del jugador, defensas y sobrecargas. La energía usada se deriva de las estructuras y sus reservas.

`save_system_test.gd` comprueba ida y vuelta, reapertura, documentos inválidos, amanecer y finales con `user://partida_test.json`. Las demás suites desactivan la persistencia antes de añadir el distrito al árbol para no leer ni modificar la partida real.

`tests/run_all.gd` ejecuta doce suites en procesos separados, comprueba códigos de salida, errores y marcadores de finalización. Devuelve 1 si alguna falla. Solo reconoce como externo el mensaje exacto de acceso denegado al almacén de certificados de Windows; lo muestra en la salida. No ignora errores de scripts ni avisos del proyecto. Los registros `validation*.log` están excluidos de Git.

`static_check.gd` carga y recompila todos los demás scripts (47); los avisos del proyecto están configurados como warning. Para la revisión final se compilaron también con todos los avisos habilitados elevados temporalmente a error, restaurando después la configuración normal. Referencia: [sistema de avisos y niveles de GDScript](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-debug-gdscript-warnings-inferred-declaration).

Las pruebas de animación del errante conservan 17 comprobaciones; las dos que exigían un corredor provisional ahora exigen su sprite y muerte animada. `visual_integration_test.gd` amplía la cobertura del corredor, constructor e interfaz provisional.


## Efectos por código

`DebrisEmitter` crea nodos pixelados con gravedad, rebote contra `GameRules.FLOOR_Y`, desvanecido y recortes reales de textura. Comparte un máximo de 120 partículas; el contador se libera en `_exit_tree`, también al cerrar la sesión. Las partículas son hermanas del actor y sobreviven a su muerte. Cada emisor utiliza un `RandomNumberGenerator` propio: no consume la aleatoriedad de las reglas.

`StructureEffects` escucha las señales de vida y dibuja grietas deterministas por sitio (66% y 33%), humo, desprendimientos y chispas de reparación. Las obras revelan el sprite desde abajo, con andamio y soldadura; al destruirse generan ocho recortes. Núcleo y jugador solo sacuden su presentación, sin mover colisiones. `EnemyVisual` añade chispas, metal y humo; `PlayerVisual` ralentiza la animación de carrera a 0,8 con poca energía y añade respiración y sudor.

`effects_test.gd` comprueba creación, liberación, persistencia tras muerte del actor, rebote, posiciones enteras, límite global, fragmentación de muralla, etapas de daño, humo, reparación y cansancio sin cambios físicos. Las simulaciones conservan 128.6 s y 240.5 s. Si el sandbox bloquea AppData, ejecutar las validaciones con `$env:APPDATA = Join-Path (Get-Location) '.godot\validation-user'`; los datos temporales quedan fuera de Git.

## HUD limpio y pausa

`HudPresenter` conserva las señales anteriores y amplía `dashboard_updated` con pausa/final, contexto y anclaje en pantalla, enemigos fuera de cámara, notificación y contadores de golpes. Escucha `HealthComponent.damaged`: curar o restaurar una partida no dispara destellos. La alerta de núcleo crítico se emite una vez por número de noche. Las amenazas detalladas conservan sus totales por frente; los chevrons solo cuentan sprites completamente fuera de los bordes horizontales, usando la transformación de cámara (incluido zoom).

`ui/hud.tscn` presenta recursos mínimos, chevrons, cartel de fase de 2,5 s, interacción sobre el objeto y toasts. `ui/damage_edges.gd` dibuja la viñeta pixelada y el aviso ámbar inferior sin shaders. La vida baja mantiene un latido hasta curarse; los temporizadores visuales se congelan al pausar. `ui/pause_panel.tscn` es una escena independiente: `Margin` aloja las filas de detalle creadas por `pause_panel.gd` y permite incorporar el futuro menú. El panel no procesa entradas ni modifica la sesión; `SessionController` sigue controlando Esc/Start.

Las estructuras y enemigos exponen `WORLD_BARS_ENABLED = false`; sus dibujos ya no incluyen barras de vida ni de obra. Permanecen contornos, revelado, grietas y partículas. `hud_clean_test.gd`, incluido en `run_all.gd`, comprueba presentación, pausa mediante la entrada existente, cámara/zoom, notificaciones y finales. Opcionalmente `-- --capture` en una ejecución gráfica guarda capturas en `.godot/`, fuera de Git.

## Repetidores y expediciones

`EnemyRepeater` usa vida de 300, `HurtboxComponent` y `StructureEffects`. Pertenece al grupo `repeaters`, separado de `enemies`: solo la hitbox del jugador consulta ambos; defensas, amenazas y oleadas siguen consultando enemigos. No tiene colision fisica ni barra de vida.

`RailwayStation` presenta el anden y la llegada del tren, con cinco ruedas rotadas por desplazamiento y particulas de `DebrisEmitter`. `ExpeditionManager` conecta los dos objetivos, habilita la estacion y valida el viaje de dia. `InteractionSystem` conserva la pulsacion mantenida y `HudPresenter` ancla el contexto sobre la estacion.

La expedicion es una escena hermana del distrito. El gestor conserva y deshabilita el modo de procesamiento de cada nodo de la colonia, incluidos Session/HUD (ALWAYS) y enemigos (PAUSABLE), y oculta mundo y HUD. Derrota libera la expedicion y restaura esos modos sin reconstruir la colonia ni tocar sus temporizadores. Victoria mantiene la suspension y muestra Continuar; R borra el guardado y reinicia como sustituto temporal del distrito 2.

El guardado sigue en version 1: `expedition.destroyed` contiene dos booleanos y `expedition.train_arrived` indica si aparco. La ausencia de estos campos equivale a torres intactas y tren ausente. Se valida antes de aplicar; un tren llegado con torres intactas se rechaza. Una llegada pendiente vuelve a iniciarse al cargar. Se conserva el autoguardado de inicio del dia.

La campana repite la ultima oleada configurada despues de la tercera noche hasta completar la expedicion; no cambia recursos de balance ni escala enemigos. La simulacion historica desactiva explicitamente `boss_required` para medir el mismo final de asedio (128.6 s / 240.5 s). `siege_smoke` comprueba el nuevo amanecer tras la tercera noche. `expedition_test`, registrada en la suite completa, verifica objetivos, llegada, restricciones, suspension, derrota, victoria y compatibilidad de guardado.

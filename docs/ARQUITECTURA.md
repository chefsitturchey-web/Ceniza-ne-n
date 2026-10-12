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

`tests/run_all.gd` ejecuta diez suites en procesos separados, comprueba códigos de salida, errores y marcadores de finalización. Devuelve 1 si alguna falla. Solo reconoce como externo el mensaje exacto de acceso denegado al almacén de certificados de Windows; lo muestra en la salida. No ignora errores de scripts ni avisos del proyecto. Los registros `validation*.log` están excluidos de Git.

`static_check.gd` carga y recompila todos los demás scripts (42); los avisos del proyecto están configurados como warning. Para la revisión final se compilaron también con todos los avisos habilitados elevados temporalmente a error, restaurando después la configuración normal. Referencia: [sistema de avisos y niveles de GDScript](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-debug-gdscript-warnings-inferred-declaration).

Las pruebas de animación del errante conservan 17 comprobaciones; las dos que exigían un corredor provisional ahora exigen su sprite y muerte animada. `visual_integration_test.gd` amplía la cobertura del corredor, constructor e interfaz provisional.

# Arquitectura actual

`levels/main.tscn` compone una colonia mediante `District`. Las entidades reciben sus datos y sistemas por referencias y señales. Los recursos `.tres` son configuración; el estado de partida pertenece a la sesión.

| Parte | Responsabilidad |
| --- | --- |
| `SessionController` y guardado | Pausa, resultados, amaneceres y checkpoint |
| Ciclo, economía y construcción | Tiempo, pagos, obras, profesiones y defensas |
| Campaña y expedición | Portales, tren, viajes y desbloqueo de distritos |
| `RecaudadorArena` | Mundo cenital aislado, jugador, jefe, dispositivos e interfaz |
| `BossTactics` | Observación, elección de ataques y navegación |
| `BossCombatEffects` | Presión secundaria, avisos, impactos y humo |
| `CombatSpriteLibrary` y `CombatFlipbook` | Atlas activos según manifiesto y reproducción de poses; incluye integraciones PixelLab posteriores al montaje ASE |
| `UnitSpriteLibrary` y `PersonVisual` | Secuencias completas de profesiones y aliados |
| `BossBattleHud`, `BossHints` y `TextMarks` | Barras, pistas y resaltado de entradas |
| `BossRush` | Secuencia de cinco arenas y ranking local independiente |
| `InputGlyphs` y `KeyRemap` | Dispositivo activo, nombres de controles y reasignación |
| `AnimatedBackdrop` y shader de movimiento | Fondos animados con máscaras por zona |
| `FirstSteps` y `FirstStepsHud` | Pasos, consejos y flecha de tutorial |
| `Preferences` y `DebugTools` | Opciones globales y práctica con F1 |

Los pagos y recompensas se resuelven en los sistemas de juego. `MainMenu.reset_guide()` reinicia pasos y consejos al crear campaña. `ColonySystem.authorize_night_work()` habilita faenas bajo riesgo hasta el amanecer. Las arenas tienen su propio `World2D` y detienen la colonia durante el encuentro. Abrir F1 no modifica el checkpoint; sus intervenciones se aíslan como práctica.

Los sprites actuales están en `assets/characters/`; los escenarios, en `assets/world/`. El combate carga directamente el manifiesto ilustrado, sin montar el paquete de sprites geométricos anterior. Las escenas de trabajadores reciben sus fotogramas de `UnitSpriteLibrary`, sin cargar PNG ocultos de versiones anteriores.

`RecaudadorArena.start_story()` y su cierre de victoria coordinan la novela automática; `rush` excluye la narración. `tests/run_all.gd` registra 67 ejecuciones mediante `tools/maintenance/validate.ps1`.

[Mapa del proyecto](../ORGANIZACION.md) · [Pruebas y mantenimiento](../../tools/README.md)

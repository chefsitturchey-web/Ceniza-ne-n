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
| `CombatSpriteLibrary` y `CombatFlipbook` | Atlas actuales de personajes y reproducción de poses |
| `UnitSpriteLibrary` y `PersonVisual` | Secuencias completas de profesiones y aliados |
| `BossBattleHud` | Vida, resistencia, fases y marcos temáticos |
| `Preferences` y `DebugTools` | Opciones globales y práctica con F1 |

Las clases de presentación no deciden pagos ni recompensas. Las arenas tienen su propio `World2D` y detienen la colonia durante el encuentro. Abrir F1 no modifica el checkpoint; sus intervenciones se aíslan como práctica.

Los sprites actuales están en `assets/characters/`; los escenarios, en `assets/world/`. El combate carga directamente el manifiesto ilustrado, sin montar el paquete de sprites geométricos anterior. Las escenas de trabajadores reciben sus fotogramas de `UnitSpriteLibrary`, sin cargar PNG ocultos de versiones anteriores.

[Mapa del proyecto](../ORGANIZACION.md) · [Pruebas y mantenimiento](../../tools/README.md)

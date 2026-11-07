# Historia: recorrido y disparadores

`data/visual_story.gd` combina `CampaignStory`, `BossDialogue` y los textos de fundación/expansión. Define 40 identificadores `distrito:sección`: ocho secciones para cada distrito de 0 a 4. El guion tiene una ruta y un final, sin decisiones ramificadas.

## Ruta

| Distrito | Escena | Jefe |
| --- | --- | --- |
| 0, Periferia | `levels/main.tscn` | Recaudador |
| 1, Fundición | `levels/zones/foundry.tscn` | Santa Caldera |
| 2, Barrio inundado | `levels/zones/flooded.tscn` | Coro Sumergido |
| 3, Ciudadela | `levels/zones/citadel.tscn` | Prefecto |
| 4, Núcleo de la red | `levels/zones/network.tscn` | Madre Cero |

`CampaignRoute.SCENES` y `ExpeditionManager` enlazan estas colonias. Completar operaciones, cerrar entradas, estabilizar y esperar el tren permite ir al jefe. La victoria resuelve la expedición y ofrece el siguiente distrito; Madre Cero cierra la campaña.

## Disparadores implementados

| Sección | Disparador y contenido |
| --- | --- |
| `opening` | `StoryDirector.queue_milestones()` encola la llegada. Funciona con la guía activa; si hay briefing o pausa, espera a que terminen. |
| `foundation` | Núcleo con `tier > 0`; `ColonyCore.complete_work()` también la encola al encenderlo. |
| `expansion` | Primera parcela con `cleared == true`. |
| `rescue` | `StoryDirector.complete(0)` y reconstrucción de pendientes al cargar. |
| `relay` | `StoryDirector.complete(1)` tras la reparación. |
| `convoy` | `StoryDirector.complete(2)` al llegar el transporte. |
| `encounter` | `RecaudadorArena.start_story()` intenta abrir la entrada de `BossDialogue` antes de `BossSpectacle.intro()`. |
| `ending` | Victoria, tras `ending_timer`, antes de emitir `resolved`. Combina despedida, cierre de capítulo y epílogo en el último distrito. |

Las cinco arenas comparten `RecaudadorArena`. La novela precede al combate; al ganar espera la muerte y presentación de victoria antes del desenlace. El temporizador de victoria se configura en 4,1 s con espectáculo o 2,2 s sin él, en tiempo de juego. La derrota no abre el desenlace de victoria.

`boss_stub.tscn` conserva un prototipo con resolución manual: no es una entrada de la ruta.

## Pausa, escenas vistas y repetición

- `NovelPanel` pausa el árbol y devuelve la pausa previa al cerrar. Bloquea la entrada residual. E, Intro, Espacio, clic y Continuar avanzan; Esc/Options omiten. Anterior permite releer.
- `StoryDirector.seen_scenes` forma parte del checkpoint. Cerrar u omitir registra la escena; cerrar el encuentro guarda ese estado antes del combate. La cola evita duplicados y reconstruye los hitos alcanzados aún no vistos al cargar.
- El traspaso de campaña incluye `story_seen`; el campo es opcional y validado. El desenlace se registra antes de resolver el viaje, evitando guardar la colonia anterior encima del siguiente distrito.
- Las arenas independientes y de práctica usan memoria de escenas vistas durante la sesión, sin escribir la campaña. El diario conserva su propia pausa al releer escenas desbloqueadas.
- La pausa de arena permite **Repetir presentacion**; en práctica añade **Leer desenlace**. `levels/story/novel_preview.tscn` ofrece la galería de los 40 identificadores.
- **Boss Rush:** `BossRush` configura cada arena con `rush = true`. `play_story()` devuelve falso, no se registran sus escenas y se oculta el botón narrativo. Solo hay combates, intermedios y resultados. [Reglas y ranking](BOSS_RUSH.md).

Los resultados y el diario mantienen resúmenes narrativos; no son escenas adicionales. El final muestra el epílogo y los créditos.

## Probar y validar

F5 → Nueva partida para comprobar la llegada con la flecha activa. En historia, entrar a un jefe, cerrar/omitir la entrada y ganar para leer el desenlace antes del viaje. F6 en `novel_preview.tscn` permite inspeccionar textos sin campaña; desde el menú, Boss Rush permite comprobar que no abre novelas.

`tests/story_flow_test.gd` comprueba entradas y desenlaces, orden con cámara/resultados, pausa, omisión con mando, escenas vistas, reintentos, 40 identificadores y exclusión de Rush. También se incluyen `visual_novel_test`, `story_finale_test`, `campaign_bosses_test`, `boss_spectacle_test` y `boss_rush_test`.

Ejecutar mediante `tools/maintenance/validate.ps1`: `tests/run_all.gd` registra 67 ejecuciones y escribe registros y `summary.json` en `build/validation/latest/`. Los scripts temporales de `build/` no son dependencias de este flujo.

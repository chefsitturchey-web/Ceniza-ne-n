# Historia: recorrido y disparadores

Auditoria del guion y del codigo de campana. Los identificadores son `distrito:seccion`; los distritos van de 0 a 4. Hay 40 escenas de novela (ocho por distrito). No se agregaron personajes ni dialogos nuevos: ya estaban escritas las llegadas, los cinco encuentros, sus despedidas y el final.

## Ruta de inicio a fin

| Distrito | Escena jugable | Voz de llegada | Jefe | Revelacion y salida |
| --- | --- | --- | --- | --- |
| 0, Una luz prestada | `levels/main.tscn` | Mara | El Recaudador | Vera encuentra el tren de personas; el rele permite una red propia; ECO reconoce su firma en el protocolo CERO. La memoria del jefe conduce a la Fundicion. |
| 1, El precio del calor | `levels/zones/foundry.tscn` | Mara e Ivo | Santa Caldera | Ivo explica el uso de recuerdos de cautivos; se separa el calor del control; Nox identifica al Consejo. La salida lleva a las estaciones sumergidas. |
| 2, Las voces bajo el agua | `levels/zones/flooded.tscn` | Ivo y Vera | Coro Sumergido | Vera distingue recuerdo y persona; se recuperan nombres; ECO admite su error. Las antenas entregan acceso a la Ciudadela. |
| 3, La ciudad que no cayo | `levels/zones/citadel.tscn` | Nox | El Prefecto | Las ordenes llevan firmas humanas; la llave exige mantener reles desde dentro; el Portador discute las puertas cerradas. ECO abre la ruta al nucleo. |
| 4, La ultima orden | `levels/zones/network.tscn` | ECO | Madre Cero | Se liberan operadores, preparan reles y recibe el ultimo transporte. ECO finaliza la emergencia y transfiere autoridad a los asentamientos. Sigue el epilogo de las cinco colonias un ano despues y los creditos. |

`CampaignRoute.SCENES` y `ExpeditionManager` enlazan estos cinco distritos. Cada distrito exige rescate, rele y convoy, cerrar entradas, estabilizar la colonia y esperar el tren para viajar al jefe. El combate ganado ofrece viajar al siguiente distrito; Madre Cero termina la campana.

## Mapa completo de escenas

Cada fila se aplica a los cinco prefijos `0`, `1`, `2`, `3`, `4`: por ejemplo, `4:encounter` es la conversacion ante Madre Cero. La suite `story_flow_test` comprueba que los 40 identificadores salen de estos disparadores.

| Seccion | Disparador real | Contenido | Estado encontrado y correccion |
| --- | --- | --- | --- |
| `opening` | Entrada a la colonia; `District._ready` y `StoryDirector.queue_milestones` | `CampaignStory.CHAPTERS.opening` mas `FRONTIER_OPENINGS` | La guia inicial bloqueaba la novela y no encolaba la llegada al terminar. Ahora la llegada se reproduce incluso con la guia activa. Si hay briefing, espera a cerrarlo. |
| `foundation` | Nucleo con `tier > 0` | `FOUNDATION_LINES` | Estaba escrita y disponible en el diario, sin disparador automatico. Ahora se encola al alcanzar el hito. |
| `expansion` | Primera parcela con `cleared == true` | `EXPANSION_LINES` | Estaba escrita pero el diario exigia haberla visto; solo la galeria permitia llegar a ella. Ahora el primer despeje la activa. |
| `rescue` | `StoryDirector.complete(0)` | Rescate de cada capitulo | Ya automatica; se recupera si se guarda antes de leerla. |
| `relay` | `StoryDirector.complete(1)` al terminar la reparacion | Rele de cada capitulo | Ya automatica; se recupera si se guarda antes de leerla. |
| `convoy` | `StoryDirector.complete(2)` al llegar el transporte al nucleo | Convoy de cada capitulo | Ya automatica; la cola pendiente impide salir en tren antes de verla. |
| `encounter` | `RecaudadorArena.start_story` | `BossDialogue.ENTRY` | Funcionaba al configurar desde colonia, pero no en apertura independiente ni practica. No registraba escenas vistas y la camara de los jefes finales arrancaba antes. Ahora la novela precede a `BossSpectacle.intro`; cerrar u omitir registra el encuentro. |
| `ending` | Victoria, al terminar `ending_timer`, antes de emitir `resolved` | `BossDialogue.EXIT`, cierre de `CampaignStory` y, en el distrito 4, `EPILOGUE` | La novela se abria al construir resultados y solo con `present_story`. Ahora se espera la muerte y la tarjeta (4,1 s de tiempo de juego para jefes con spectacle; 2,2 s para los otros), se lee la novela y luego se resuelve la expedicion. |

Las escenas de arenas `recaudador_arena`, `caldera_arena`, `choir_arena`, `prefect_arena` y `mother_arena` comparten el controlador. No hay otra ruta narrativa en `boss_stub.tscn`: es un prototipo con resolucion manual, no una entrada de `CampaignRoute`.

## Guardado, repeticiones y controles

- La novela pausa el arbol. Al cerrar recupera el estado previo y bloquea la entrada residual. Esc o Start omiten; E, aceptar, espacio y el boton Continuar avanzan. El diario conserva su propia pausa al releer.
- `StoryDirector.seen_scenes` es parte del checkpoint existente. Cerrar el encuentro guarda ese estado antes de combatir; reintentar desde la colonia o cargar el checkpoint no lo repite. La cola evita duplicados y no vuelve a encolar la escena abierta.
- El traspaso entre distritos lleva `story_seen`, opcional y validado. Los guardados anteriores sin ese campo siguen siendo validos. Al cargar, los hitos alcanzados que no figuran como vistos vuelven a encolarse.
- El desenlace no escribe un checkpoint de la colonia anterior encima del siguiente distrito. En el flujo normal se registra antes de que `ExpeditionManager.resolve` guarde el traspaso.
- Las arenas independientes y de practica conservan escenas vistas durante la sesion, sin escribir en la campana. Cerrar y abrir el ejecutable reinicia esa memoria de practica.
- El diario permite releer las conversaciones desbloqueadas. La pausa del jefe conserva la repeticion de presentacion y, en practica, desenlace. `levels/story/novel_preview.tscn` es una galeria de los 40 identificadores y no guarda campana.
- `boss_rush.tscn` carga `BossRush`, que crea cada arena con `rush = true`. Ese flag excluye entrada, desenlace y el boton narrativo, incluso si `present_story` esta activado. Solo hay combates, intermedios y resultados de Rush.

## Texto recuperado y limites

Se incorporaron a la novela los cierres de capitulo ya escritos y el epilogo, antes visibles como prosa de resultados. Los resultados y el diario conservan esa prosa como resumen; no son nuevas escenas ni vuelven a abrir la novela. No fue necesario inventar una llegada ni una conversacion anterior al ultimo jefe: ambas existian.

La victoria final sigue mostrando automaticamente el epilogo y los creditos en resultados. La campana mantiene un unico final escrito; no hay decisiones ramificadas en el guion auditado.

## Comprobacion

`tests/story_flow_test.gd` cubre los cinco encuentros y desenlaces, pausa, omision con mando, orden frente a la camara y resultados, 40 identificadores, restauracion y reintentos, y exclusion explicita de Rush. `visual_novel_test`, `story_finale_test`, `campaign_bosses_test`, `boss_spectacle_test` y `boss_rush_test` conservan sus comprobaciones.

Capturas con ventana y entrada simulada: `build/capturas/historia/`. Script de captura: `build/captura_historia.gd`. La validacion usa `tools/maintenance/validate.ps1`; el ejecutor temporal `build/validate_story_serial.ps1` recorre las suites sin mantener otro Godot como proceso coordinador.

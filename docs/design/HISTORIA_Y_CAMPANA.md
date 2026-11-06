# Historia y campaña actual

`CampaignRoute.SCENES` conecta cinco distritos: Periferia, Fundición, Barrio inundado, Ciudadela y Núcleo de la red. Sus jefes son Recaudador, Santa Caldera, Coro Sumergido, Prefecto y Madre Cero. Los perfiles de `FrontierLayout` contienen cero, una, dos, tres y tres brechas intermedias por lado, además de los repetidores terminales: 2, 4, 6, 8 y 8 entradas en total.

## Operaciones y viaje

`systems/story_director.gd` gestiona tres operaciones por distrito: rescate, reparación del relé y escolta del convoy. La ubicación sale del perfil de mapa; varía con la semilla. Consultar el HUD y **L** en vez de usar las antiguas coordenadas del prototipo.

El relé necesita energía, pago y un técnico que llegue a trabajar. El convoy requiere acompañamiento y tropa; una avería puede repararse. Las operaciones y sus recompensas se guardan para no duplicarlas al cargar. El tren exige operaciones completas, entradas cerradas y estabilidad de colonia; se toma de día. `systems/expedition_manager.gd` resuelve el encuentro y prepara el siguiente distrito, o el final tras Madre Cero.

## Novela visual

`data/campaign_story.gd`, `data/boss_dialogue.gd` y `data/visual_story.gd` contienen el guion actual: 40 escenas, ocho por distrito. Llegada, fundación, expansión, rescate, relé, convoy, encuentro y desenlace tienen disparadores. La entrada del jefe precede al combate; la victoria abre el desenlace antes de resolver la expedición. Las escenas vistas se conservan y el diario permite releerlas. El final incluye epílogo y créditos.

Boss Rush reutiliza los jefes con `rush = true` y excluye novela visual. Las arenas abiertas directamente y las prácticas tienen memoria narrativa de sesión. [Disparadores, pausa y guardado](../gameplay/HISTORIA_FLUJO.md).

## Alcance

El código contiene una ruta y un final sin decisiones ramificadas. No se ha medido aquí una campaña humana de cuatro horas. Los mapas por semilla y la reasignación de controles ya existen; no deben figurar como pendientes. El GDD es una referencia y no una lista de funciones terminadas ni de trabajos futuros confirmados.

## Probar

F5 → Nueva partida, seguir objetivos y abrir el diario. F1 en editor/depuración permite practicar cada jefe; F6 en `levels/story/novel_preview.tscn` recorre el guion sin campaña. Las suites `story_flow_test`, `story_finale_test` y `campaign_bosses_test` se ejecutan con `tools/maintenance/validate.ps1`, dentro de las 67 ejecuciones generales.

[Inicio](../../INICIO.md) · [Frontera](../gameplay/FRONTERA_Y_RECONSTRUCCION.md) · [Boss Rush](../gameplay/BOSS_RUSH.md).

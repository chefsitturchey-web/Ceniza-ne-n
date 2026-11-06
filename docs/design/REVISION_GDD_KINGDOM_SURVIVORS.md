# GDD y mecánicas implementadas

El [GDD original](CENIZA_NEON_GDD.docx) es una referencia de diseño. Esta guía describe el código actual; no presenta todo su catálogo como implementado ni convierte propuestas en compromisos de producción.

| Sistema | Implementación actual | Fuente |
| --- | --- | --- |
| Ruta | Cinco distritos y cinco jefes | `systems/campaign_route.gd` |
| Mapas | Perfiles por zona y variación determinista por semilla | `data/frontier_layout.gd` |
| Construcción | Pago, viaje y trabajo de constructores; despejes y niveles | `systems/colony_system.gd`, `systems/frontier_system.gd` |
| Profesiones | Recluta y herramienta separados; plazas según infraestructura | `systems/civic_system.gd` |
| Combate de colonia | Tropas, torretas y sobrecarga; módulos con bonificaciones de mando | `systems/module_system.gd` |
| Recursos | Chatarra, mochila, depósito y componentes de poblados | `systems/resource_bank.gd`, `systems/settlement_system.gd` |
| Experiencia | Datos físicos, subida de nivel y elecciones | `systems/experience_system.gd`, `ui/level_choice_panel.gd` |
| Equipo | Tres módulos, dos ranuras; seis pasivas, cuatro equipadas; evoluciones | `systems/module_system.gd` |
| Historia | 40 escenas, operaciones, desenlace y repetición | `data/visual_story.gd`, `systems/story_director.gd` |
| Interfaz | Reasignación y avisos por dispositivo | `core/key_remap.gd`, `core/input_glyphs.gd` |
| Boss Rush | Cinco combates y ranking local | `levels/expedition/boss_rush.gd` |

La relación de campamentos, herramientas, obras y frentes se aplica en la colonia; las arenas conservan combate personal y equipo automático. Una orden nocturna expone a los trabajadores al riesgo. El núcleo empieza sin construir, las torretas exigen Nv.2 y los tiempos actuales se describen en [Frontera](../gameplay/FRONTERA_Y_RECONSTRUCCION.md).

## Límites comprobables

La lista activa de módulos contiene dron, Tesla y orbital; la ruta tiene un único final escrito. Las guías no prometen el resto del catálogo del GDD, decisiones ramificadas ni cuatro horas medidas de campaña. Las simulaciones automáticas comprueban reglas y recorridos concretos; no equivalen a pruebas humanas de duración o dificultad.

## Comprobar

F5 → Nueva partida para construcción, reclutamiento y experiencia. F6 en `levels/zones/expansion_playground.tscn` permite práctica. `tests/gdd_foundations_test.gd` contiene comprobaciones de los sistemas base; `expansion_test.gd` es su entrada heredada. Ejecutar con `tools/maintenance/validate.ps1`; `run_all.gd` registra 67 ejecuciones.

[Campaña](HISTORIA_Y_CAMPANA.md) · [Comandante](../gameplay/COMANDANTE_Y_PORTALES.md) · [Equipo](../gameplay/MODULOS_Y_EVOLUCIONES.md).

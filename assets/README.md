# Recursos del juego

| Carpeta | Qué contiene |
| --- | --- |
| `characters/combat/` | Portador lateral y cenital, Recaudador, Caldera, Coro, Prefecto y Madre |
| `characters/units/` | Atlas de las nueve profesiones y unidades aliadas, con sus fuentes ASE |
| `characters/enemies/` | Secuencias usadas por los enemigos de colonia |
| `characters/pests/` | Rata con ocho poses de marcha y fuente editable de LibreSprite |
| `characters/portraits/` | Retratos manga de la novela visual |
| `world/backgrounds/` | `layers/`: cinco arquitecturas transparentes y horizonte; `sources/`: ASE; `references/`: pinturas de entrada; `masks/`: datos de animación del fondo |
| `world/structures/` | Núcleo, edificios, murallas, torretas y suelo |
| `world/props/` | Objetos del escenario lateral |
| `world/salvage/` | Batería, antena, trampa y piezas recuperables; PNG y fuentes ASE |
| `world/settlements/` | Fachadas en ruinas, instalaciones recuperables y componentes técnicos, con editables ASE |
| `world/expedition/` | Tren, estación, repetidores y piezas de las arenas |
| `ui/` | Iconos, arte de menú y `frames/`: seis marcos ornamentales de vida |
| `fonts/` | Fuentes y sus licencias |
| `audio/` | 21 temas OGG; efectos activos de 8 bits en `sfx/8bit/`, voces sintéticas y licencias |

Los PNG, OGG y WAV son recursos finales. `sources/` conserva archivos editables y clips de entrada, y `references/` las pinturas utilizadas por las herramientas; no son copias sobrantes del juego. `layout.json` define celdas, anclajes y animaciones. `provenance.json` registra procedencia y hashes de las fuentes. El Portador lateral y los dos jefes finales tienen PNG con integraciones posteriores de PixelLab; sus ASE base no representan todos los fotogramas activos. Consultar [reconstrucción de combate](../docs/art/ARTE_COMBATE_ILUSTRADO.md).

Los `.import` y `.gd.uid` mantienen ajustes e identificadores de Godot. La caché de importación vive en `.godot/`, fuera de Git.

El icono y la fuente de la mochila están en `ui/icons/frontier/`. [Reglas y procedencia del nuevo arte](../docs/gameplay/FRONTERA_Y_RECONSTRUCCION.md).

Las bibliotecas actuales (`CombatSpriteLibrary`, `UnitSpriteLibrary`, `GameSound` y `MusicLibrary`) permiten comprobar qué recursos se cargan. Validación: `tools/maintenance/validate.ps1`, con 67 ejecuciones en `tests/run_all.gd`.

Se retiraron las carpetas anteriores `player/`, `unidades/` y `combat/native/`, los dos fondos de parallax sustituidos, cinco piezas de jefe sueltas reemplazadas por un atlas y las dos músicas sintéticas que ya no utilizaba el repertorio. Las escenas y bibliotecas cargan exclusivamente sus sustitutos actuales.

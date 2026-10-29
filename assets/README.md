# Recursos del juego

| Carpeta | Qué contiene |
| --- | --- |
| `characters/combat/` | Portador lateral y cenital, Recaudador, Caldera, Coro, Prefecto y Madre |
| `characters/units/` | Atlas de las nueve profesiones y unidades aliadas, con sus fuentes ASE |
| `characters/enemies/` | Secuencias usadas por los enemigos de colonia |
| `characters/portraits/` | Retratos manga de la novela visual |
| `world/backgrounds/` | `layers/`: cinco arquitecturas transparentes y horizonte; `sources/`: ASE; `references/`: pinturas de entrada |
| `world/structures/` | Núcleo, edificios, murallas, torretas y suelo |
| `world/props/` | Objetos del escenario lateral |
| `world/expedition/` | Tren, estación, repetidores y piezas de las arenas |
| `ui/` | Iconos, arte de menú y `frames/`: seis marcos ornamentales de vida |
| `fonts/` | Fuentes y sus licencias |
| `audio/` | Música, efectos, configuración de bucle y licencias |

Los PNG y OGG son recursos finales. `sources/` conserva los archivos editables de LibreSprite y `references/` las pinturas de entrada que utiliza el generador actual; no son copias sobrantes del juego. `layout.json` define celdas, anclajes y animaciones. `provenance.json` registra procedencia y hashes de las fuentes.

Los `.import` y `.gd.uid` mantienen ajustes e identificadores de Godot. La caché de importación vive en `.godot/`, fuera de Git.

Se retiraron las carpetas anteriores `player/`, `unidades/` y `combat/native/`, los dos fondos de parallax sustituidos, cinco piezas de jefe sueltas reemplazadas por un atlas y las dos músicas sintéticas que ya no utilizaba el repertorio. Las escenas y bibliotecas cargan exclusivamente sus sustitutos actuales.

# Arte de recuperación

Píxeles originales dibujados dentro de LibreSprite con `tools/art/libresprite_frontier.js`. Python solo prepara los documentos vacíos; LibreSprite escribe las capas y exporta los PNG.

| Recurso | Celda | Contenido |
|---|---|---|
| `battery.png` | 32×32 | Celdas, bornes, cable y carcasa corroída |
| `antenna.png` | 32×48 | Mástil, receptores, cableado y consola |
| `trap.png` | 32×24, tres celdas horizontales | Abierta, cerrada y activada |
| `parts.png` | 16×16 | Chip, bobina y tuerca |

Las fuentes editables están en `sources/*.ase`. La rata animada está en `assets/characters/pests/`, y la mochila de interfaz en `assets/ui/icons/frontier/`, con sus respectivas fuentes. No regenerar sobre una edición manual: el constructor se detiene si encuentra una fuente existente.

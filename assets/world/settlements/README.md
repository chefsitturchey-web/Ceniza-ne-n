# Poblados industriales

| Atlas | Celda | Variantes |
|---|---|---|
| `ruins.png` | 128×144 | Diez fachadas: dos por distrito |
| `supports.png` | 96×96 | Taller, armería y dispensario, dos niveles cada uno |
| `components.png` | 24×24 | Servomotor, bobina y membrana filtrante |

Fuentes editables: `sources/*.ase`. Las variantes se disponen horizontalmente en PNG; los editables las conservan como fotogramas separados. Dibujo, muestreo, máscaras de daño y exportación realizados dentro de LibreSprite. El atlas industrial aprobado es la referencia y fuente de textura; permanece sin cambios.

Generador: `tools/art/build_settlement_art.py`, con trabajo nativo en `libresprite_settlements.js`. Los archivos temporales se escriben en `build/art-settlements/`. Las fuentes existentes se preservan. [Mecánicas y costes](../../../docs/gameplay/POBLADOS_Y_TECNOLOGIA.md).

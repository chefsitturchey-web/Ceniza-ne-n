# Herramientas de desarrollo

Ejecutar desde la raíz del proyecto. Godot no importa esta carpeta.

| Carpeta | Uso |
| --- | --- |
| `art/` | Montaje, edición nativa y exportación de sprites con LibreSprite; medición de anclajes y galería de trabajo |
| `audio/` | Preparación de sonidos CC0 e importación de la música actual |
| `integrations/` | Puente del MCP PixelLab, descarga de poses e importador de animaciones |
| `maintenance/` | Ejecución de pruebas y limpieza de archivos generados |

## Comandos habituales

```powershell
python tools/art/build_illustrated_combat.py --help
python tools/art/build_unit_sprites.py --help
python tools/art/live_combat_board.py --help
./tools/maintenance/validate.ps1 -GodotPath "RUTA/Godot_console.exe"
./tools/maintenance/clean_generated.ps1
```

Los generadores de arte necesitan LibreSprite; `--libresprite` permite indicar su ubicación. Los ASE editables y sus metadatos están dentro de `assets/`, junto a los PNG de juego. Los trabajos intermedios continúan en `.godot/`; no se mezclan con los dibujos aprobados. `build_unit_sprites.py` utiliza normalmente `assets/characters/units/sources/pose_reference.ase`, sin depender de una descarga nueva.

Las integraciones externas solo son necesarias al generar recursos nuevos. El juego y sus pruebas funcionan sin conexión a esas cuentas. `pixellab_mcp.py` utiliza la configuración local del usuario; no se deben copiar credenciales al repositorio.

La validación acepta `-Suite boss_hud_test` para una prueba concreta y `-ImportOnly` para comprobar la importación. También reconoce `GODOT_BIN` o un ejecutable Godot disponible en `PATH`. No usa las partidas del jugador.

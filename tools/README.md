# Herramientas de desarrollo

Ejecutar desde la raíz del proyecto. Godot no importa esta carpeta.

| Carpeta | Uso |
| --- | --- |
| `art/` | Montaje LibreSprite, integración de clips PixelLab con Python/Pillow, medición y galerías |
| `audio/` | Preparación de sonidos CC0 e importación de la música actual |
| `integrations/` | Puente del MCP PixelLab, descarga de poses e importador de animaciones |
| `maintenance/` | Ejecución de pruebas y limpieza de archivos generados |

Los generadores de audio de 8 bits actualmente están en `tools/generar_efectos.py` y `tools/generar_voces.py`; este último importa el primero. Se conservan sus rutas y la dependencia. [Audio activo](../docs/audio/AUDIO.md).

## Comandos habituales

```powershell
python tools/art/build_illustrated_combat.py --help
python tools/art/build_unit_sprites.py --help
python tools/art/build_environment_art.py --help
python tools/art/live_combat_board.py --help
./tools/maintenance/validate.ps1 -GodotPath "RUTA/Godot_console.exe"
./tools/maintenance/clean_generated.ps1
```

Los generadores de montaje ASE necesitan LibreSprite; `--libresprite` permite indicar su ubicación. Los ASE editables y sus metadatos están dentro de `assets/`, junto a los PNG de juego. Los intermedios se guardan según herramienta en `.godot/` o `build/`; no se mezclan con los dibujos aprobados. `build_unit_sprites.py` utiliza normalmente `assets/characters/units/sources/pose_reference.ase`, sin depender de una descarga nueva.

Las integraciones externas solo son necesarias al generar recursos nuevos. El juego y sus pruebas funcionan sin conexión a esas cuentas. `pixellab_mcp.py` utiliza la configuración local del usuario; no se deben copiar credenciales al repositorio.

La validación acepta `-Suite boss_hud_test` para una prueba concreta y `-ImportOnly` para comprobar la importación. También reconoce `GODOT_BIN` o un ejecutable Godot disponible en `PATH`. Aísla `APPDATA` en `build/validation/user-data/` para no usar las partidas del jugador. `tests/run_all.gd` registra 67 ejecuciones y escribe registros y `summary.json` en `build/validation/latest/`.

`integrar_portador_pixellab.py` y `integrar_jefes_pixellab.py` escriben los PNG activos a partir de clips locales y no actualizan los ASE. Consultar [arte de combate](../docs/art/ARTE_COMBATE_ILUSTRADO.md) antes de reconstruirlos.

`build_environment_art.py` monta doce fuentes ASE (fondos y marcos) mediante el script nativo `libresprite_environment.js`. Guarda intermedios en `build/art-depth/` y protege las ediciones manuales mediante SHA-256. Consulta [Fondos en capas](../docs/art/FONDOS_EN_CAPAS.md).

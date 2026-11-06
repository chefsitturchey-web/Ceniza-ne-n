# Organización y archivos generados

`project.godot` inicia el menú. El GDD está en `docs/design/CENIZA_NEON_GDD.docx`; las guías actuales se encuentran en el [índice](README.md).

| Carpeta | Contenido comprobable |
| --- | --- |
| `core/` | Reglas, entradas, reasignación y ajuste de pantalla |
| `components/` | Vida, animación, efectos y fondos |
| `entities/` | Jugador, enemigos, trabajadores, estructuras y objetos |
| `systems/` | Economía, construcción, campaña y guardado |
| `levels/` | Colonias, arenas, Boss Rush y galerías |
| `ui/` | Menús, controles táctiles, HUD y novela visual |
| `data/` | Scripts de datos, recursos `.tres` y metadatos de arte |
| `assets/` | Recursos de juego, fuentes editables, referencias y licencias |
| `tests/` | Pruebas y simulaciones |
| `tools/` | Arte, audio, integraciones y mantenimiento |
| `docs/` | Guías por tema, referencias y capturas seleccionadas |

Los personajes se guardan en `assets/characters/` y los escenarios en `assets/world/`. Las fuentes y referencias usadas por herramientas se conservan aunque el juego no las cargue directamente. Los `.import` y `.gd.uid` acompañan a sus recursos; `.godot/` es caché local.

## Validación y limpieza

`tools/maintenance/validate.ps1` importa y ejecuta las pruebas con `APPDATA` aislado en `build/validation/user-data/`. `tests/run_all.gd` registra 67 ejecuciones, incluidas variantes. Escribe registros por suite en `build/validation/latest/suites/` y resultado en `build/validation/latest/summary.json`.

```powershell
./tools/maintenance/validate.ps1 -GodotPath "RUTA/Godot_console.exe"
./tools/maintenance/validate.ps1 -GodotPath "RUTA/Godot_console.exe" -Suite boss_rush_test
./tools/maintenance/clean_generated.ps1
```

`clean_generated.ps1` elimina `validation*.log` de la raíz y cachés Python de `tools/`. Con `-Validation` elimina también `build/validation/`. No usar esa opción antes de consultar los resultados que se quieran conservar. `build/.gdignore` y las reglas de `.gitignore` separan las salidas locales del contenido versionado.

Para retirar un archivo, buscar ruta, nombre y, en scripts, `class_name` en código, escenas, recursos, documentación y herramientas. Una clase global puede usarse sin ruta explícita. Ante la duda, conservarla. No se deduce el estado de otras carpetas de trabajo o publicaciones a partir de este repositorio.

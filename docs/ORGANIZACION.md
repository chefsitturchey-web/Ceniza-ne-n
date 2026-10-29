# Organización y archivos generados

La raíz contiene las entradas del proyecto: `project.godot`, el bus de audio, README, INICIO y las instrucciones de trabajo. El documento de diseño se encuentra ahora en [`design/CENIZA_NEON_GDD.docx`](design/CENIZA_NEON_GDD.docx), sin modificaciones en su contenido.

## Código y recursos

| Carpeta | Contenido |
| --- | --- |
| `core/` | Reglas y controles compartidos |
| `components/` | Vida, impactos, animación y efectos reutilizables |
| `entities/` | Jugador, enemigos, trabajadores y estructuras |
| `systems/` | Economía, construcción, campaña, inteligencia y guardado |
| `levels/` | Escenas y composición del mundo, expediciones y galerías |
| `ui/` | Menús, HUD y paneles |
| `data/` | Recursos y configuraciones de juego |
| `assets/` | Arte y sonido de juego, licencias, fuentes editables y procedencia |
| `tests/` | Pruebas y simulaciones; `run_all.gd` es la entrada general |
| `tools/` | Herramientas separadas por arte, audio, integraciones y mantenimiento |
| `docs/` | Guías, diseño, referencias y capturas seleccionadas |

Las imágenes aportadas como referencia están en `docs/references/`; las capturas de entregas documentadas, en `docs/media/`. `docs/GUIA_ARTE.md` conserva los ajustes del usuario. El [índice](README.md) permite encontrar las guías por tema.

Los recursos de `assets/unidades/`, `assets/units/`, combate nativo y combate ilustrado no son duplicados que se puedan borrar indiscriminadamente: todavía existen referencias, animaciones originales y rutas de respaldo. Se mantienen sus nombres para conservar esas dependencias y los identificadores de Godot.

Los archivos `.import` guardan ajustes de importación y los `.gd.uid` conservan identificadores de scripts. Se mantienen junto a su recurso. La caché regenerable está dentro de `.godot/`, que Git ignora.

## Por qué había tantos archivos validation

Las ejecuciones anteriores generaban un registro distinto para cada intento, importación y captura. Estaban ignorados por Git, pero se acumulaban físicamente en la raíz. Se eliminaron **394 registros antiguos y cinco archivos de caché Python**.

Desde esta reorganización, `tests/run_all.gd` escribe en `build/validation/latest/suites/`, con un nombre estable por prueba y variante. Así, las cinco simulaciones de zona conservan registros distintos sin crear nuevos nombres en cada intento. `summary.json` contiene el resultado de las 40 suites.

```powershell
# Importar y ejecutar todas las pruebas, con perfil aislado:
./tools/maintenance/validate.ps1 -GodotPath "RUTA/Godot_console.exe"
# Una suite concreta:
./tools/maintenance/validate.ps1 -GodotPath "RUTA/Godot_console.exe" -Suite boss_hud_test
# Limpiar logs antiguos de la raíz y cachés Python:
./tools/maintenance/clean_generated.ps1
# Borrar también los resultados y perfiles locales de pruebas:
./tools/maintenance/clean_generated.ps1 -Validation
```

`build/` está excluido de Godot y de Git, salvo su marcador `.gdignore`. `.godot/` contiene importaciones automáticas y trabajos intermedios de herramientas; la limpieza no lo borra. Tampoco borra partidas del usuario, fuentes ASE ni recursos de audio.

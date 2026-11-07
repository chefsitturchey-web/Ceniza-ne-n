# Cómo colaborar en CENIZA NEÓN

Guía corta para quien vaya a hacer cambios. Lo demás está en el [índice de documentación](docs/README.md).

## Preparar

1. Instala **Godot 4.7.2** (estable). Otras versiones pueden reordenar o romper recursos.
2. Clona el repositorio y abre `project.godot`. Espera a que termine la importación.
3. **F5** abre `ui/main_menu.tscn`. **F1** abre el laboratorio de depuración (jefes, fases y trucos).

## Ramas

- `main` es la versión estable y la que se publica.
- Trabaja en una rama propia (`tu-nombre/tema`) y abre un Pull Request contra `main`.
- Un commit = un cambio coherente y probado. Mensajes en español, describiendo qué cambia para el jugador.
- No subas `.godot/`, `build/`, exportaciones ni logs (ya están en `.gitignore`).
- Si Godot solo cambia finales de línea en archivos `.import` o reordena `project.godot` al exportar, descarta esos cambios (`git checkout -- <archivo>`).

## Probar antes de subir

```powershell
powershell -File tools\maintenance\validate.ps1 -GodotPath "<ruta a Godot_v4.7.2-stable_win64_console.exe>"
```

Deben pasar las **67 ejecuciones** de `tests/run_all.gd`. El resumen queda en `build/validation/latest/summary.json`. Si cambias textos de controles, menús o pistas, revisa `tests/ui_guidance_test.gd`, `tests/text_marks_test.gd` y `tests/key_remap_test.gd`: comparan textos exactos.

## Dónde está cada cosa

| Quieres cambiar… | Mira en |
| --- | --- |
| Controles, mando, nombres de botones | `core/input_setup.gd`, `core/key_remap.gd`, `core/input_glyphs.gd`, `ui/text_marks.gd` |
| Colonia, construcción, rondas | `systems/`, `entities/structures/`, `data/` |
| Jefes y arenas | `levels/expedition/` |
| Boss Rush y ranking | `levels/expedition/boss_rush.gd`, `levels/expedition/online_ranking.gd` |
| Historia y novela visual | `levels/story/`, [HISTORIA_FLUJO](docs/gameplay/HISTORIA_FLUJO.md) |
| Menús e interfaz | `ui/` |
| Arte y sonido | `assets/` ([qué hay y dónde](assets/README.md)) |

La arquitectura general está en [ARQUITECTURA](docs/development/ARQUITECTURA.md).

## Documentación

- Si cambias una mecánica, actualiza su guía en `docs/` y, si es visible para el jugador, `README.md` e `INICIO.md`.
- Describe lo que el código hace hoy, no lo que se planea. Lo planeado va marcado como tal.
- Registra el arte nuevo en `docs/art/ASSET_SOURCES.csv` con su procedencia y licencia.

## Versiones y publicación

La versión está en cuatro sitios y deben coincidir: `project.godot` (`config/version`), `export_presets.cfg` (`version/name` y `version/code` de Android, que sube en 1 cada versión), `README.md` y `docs/EXPORTAR.md`. Los pasos de exportación están en [EXPORTAR](docs/EXPORTAR.md).

Publicar (release en GitHub, itch.io, web) lo decide el responsable del proyecto.

## Servicios externos

- **Ranking online:** API en el Worker de Cloudflare de la web (`ceniza-neon-web`, carpeta `worker/`, base D1 `ceniza-ranking`). Si cambias el formato de envío en `online_ranking.gd`, cambia también el Worker. Detalles en [BOSS_RUSH](docs/gameplay/BOSS_RUSH.md).
- **Web del juego:** https://ceniza-neon.chefsitturchey.workers.dev/ — repositorio aparte.
- **itch.io:** https://chefsitturchey.itch.io/ceniza-neon

## Créditos

Carlos Alberto Llano Flores (Turchey): dirección, diseño y programación. Timoteo: música, efectos y menús. Todos los derechos reservados mientras no se publique una licencia.

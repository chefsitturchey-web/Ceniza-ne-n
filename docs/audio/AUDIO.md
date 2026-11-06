# Audio actual

`systems/music_library.gd` carga 21 OGG desde `assets/audio/music/`: menú, siete variantes de día repartidas entre cinco distritos, noche, aviso, victoria, derrota y nueve temas de jefe. Cualquier jefe puede recibir cualquiera de esos nueve temas; el nombre del archivo no lo fija a un encuentro.

`systems/game_sound.gd` carga los efectos activos de `assets/audio/sfx/8bit/`, organizados en combate, economía, hitos, interfaz, plagas y voz. Usa voces limitadas y prioridades para los avisos, audio espacial del mundo y ambientes por zona. `systems/ui_sound.gd` comparte clic, foco, roce y regreso de los paneles; precarga su caché mediante `warm_up()` y dispara el clic al presionar.

`systems/voice_library.gd` selecciona sonidos breves de diálogo: cinco timbres, cuatro emociones y cinco variantes de altura, con asignación por hablante. `ui/novel_panel.gd` los reproduce durante la revelación del texto. Son sonidos sintéticos, no locución de frases ni sincronización labial.

Master, Music y SFX se ajustan desde Opciones; **M** alterna silencio global. La novela atenúa la música. El relevo de temas usa salida y entrada gradual. Los audios y sus ajustes de importación están versionados junto con sus licencias; no atribuir todo el repertorio activo a los antiguos efectos CC0.

## Herramientas y prueba

`tools/audio/importar_musica.py` y `preparar_sonidos.py` contienen importación/preparación. Los generadores actuales de efectos y voces están en `tools/generar_efectos.py` y `tools/generar_voces.py`; el segundo importa el primero. No son scripts sobrantes ni deben borrarse por carecer de llamadas desde Godot.

F5: escuchar menú y colonia, cambiar volúmenes y abrir una conversación. F1 en editor/depuración permite comparar los jefes. Para comprobar transiciones escuchar aviso, noche, victoria y derrota. Las pruebas sin ventana no sustituyen esta escucha: `GameSound` desactiva reproducción con el controlador headless.

Validar mediante `tools/maintenance/validate.ps1`; `neural_audio_test` y `music_handoff_test` están en las 67 ejecuciones de `tests/run_all.gd`. Registros en `build/validation/latest/`.

[Herramientas](../../tools/README.md).

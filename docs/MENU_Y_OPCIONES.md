# Menú y opciones persistentes

F5 abre el menú principal. Continuar muestra el día y la chatarra del último guardado compatible. Nueva partida pide una elección dentro del juego cuando existe un archivo y conserva una copia completa en `user://partida.json.anterior` antes de liberar el slot. Si falla la copia, no empieza la partida nueva. Un archivo ilegible no se borra al consultar el menú; si una carga completa falla, la sesión intenta archivarlo antes de generar otro.

Opciones está disponible desde el menú y desde la pausa de la colonia. Sus cambios se aplican inmediatamente y se guardan en `user://opciones.cfg`: volumen general, música, efectos, silencio, pantalla completa, tres tamaños de ventana, reducción de destellos/sacudidas y partículas. Los porcentajes se aplican sobre el volumen original de los buses; se conserva su margen y sus efectos. M cambia el silencio global, también durante la expedición. Cerrar opciones abiertas desde pausa conserva la pausa.

Los ajustes son el primer autoload del proyecto (`Preferences`): solo contienen preferencias de presentación, sin reglas ni progreso de la colonia. Los valores inválidos del archivo usan sus defaults; los demás se conservan. La interfaz informa si no puede guardar. F6 en `levels/main.tscn` sigue permitiendo probar directamente el distrito.

## Validación

`tests/menu_settings_test.gd`: 22 comprobaciones de persistencia, tipos inválidos, canales de audio, sliders, navegación, confirmación de nueva colonia, archivo de guardado y pausa. También verifica que desactivar partículas evite crear nodos decorativos. No lee ni modifica la partida del usuario: usa archivos de prueba. `tests/run_all.gd` añade esta suite a las 17 anteriores. Las capturas opcionales con `-- --capture` quedan en `.godot/menu-principal.png` y `.godot/opciones.png`; ambas fueron revisadas con OpenGL.

El compilador estático carga los scripts en un proceso nuevo y comprueba que sean instanciables. Evita recompilar una clase que ya tiene el autoload activo. En esta comprobación, Godot sigue informando referencias al cerrar (`debris_emitter.gd` y `game_preferences.gd`); las pruebas de juego y navegación no reproducen ese aviso. El total histórico de suites sigue leyendo el log de Godot y no certifica ausencia de mensajes tardíos de stderr, como se explicó en `REVISION_Y_AUDIO.md`.

## Arte incorporado

Ilustración nueva del menú: `assets/menu/ruinas_menu.png`, generada con la herramienta integrada de imagegen. No se sustituyeron sprites del juego. El título, botones y velo de legibilidad se dibujan en Godot. Se conservó el PNG original generado, sin editarlo.

Prompt usado:

> Create an original game main menu background illustration for CENIZA NEON. No text, no logo, no user interface. Wide landscape 16:9 composition, 1536x864 preferred. Detailed pixel art, crisp square pixel clusters, selective dark outlines, atmospheric side-view abandoned industrial cyberpunk city at night. Palette dark navy #0B1322 #182639 #304356, steel #8299A8, sparse cyan #47DACB, amber #FFCE75, hostile sensors pink #DD6482, matte rust #E89E54. RIGHT HALF: a small lone human neural-key carrier seen from behind in 3/4 view, short charcoal utility jacket, compact steel shoulder plate, amber rectangular visor, one small cyan battery on back, lowered short industrial cutting blade, standing next to a salvaged cyan-lit colony relay on a wet railway platform. Distant armored train, ruined elevated rails and factories. Fine falling ash, restrained warm lamps, puddle reflections and volumetric haze, no excessive bloom. LEFT HALF: quieter dark navy atmospheric negative space, distant silhouettes and minimal detail, suitable for overlaid readable menu title/buttons drawn separately in the game. Grounded functional machinery, melancholy resilience, detailed metal bolts and cables on focal structures. No cape, no gun, no isometric game view, no photorealism, no smooth vector look, no recognizable existing franchise characters.

Referencias técnicas: [ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html) y [DisplayServer](https://docs.godotengine.org/en/stable/classes/class_displayserver.html), documentación oficial de Godot.

# Menús, opciones y controles

## Inicio y guardado

`ui/main_menu.gd` ofrece Continuar, Nueva partida, Boss Rush y Opciones. Nueva partida solicita confirmación dentro del juego cuando hay un guardado y utiliza `SaveSystem.archive_checkpoint()` antes de liberar el slot. El respaldo es `user://partida.json.anterior`; si falla el archivado, no inicia la nueva campaña.

Nueva partida restablece `guide` y `tips` de `user://progreso_pixel.cfg`, conservando récord y logros. Continuar recupera el checkpoint y el progreso del perfil. El ranking de Boss Rush está separado en `user://boss_rush.cfg`. [Boss Rush](../gameplay/BOSS_RUSH.md).

## Opciones y pausa

`systems/game_preferences.gd`, autoload `Preferences`, conserva preferencias y asignaciones en `user://opciones.cfg`: volumen general, música, efectos, silencio, pantalla completa, tamaño, destellos reducidos, partículas, controles táctiles y modo de avisos. **M** alterna silencio.

Opciones se abre desde el menú y desde las pausas de colonia y arena. `ui/pause_panel.gd` muestra una tabla de controles de colonia; en arena, las pistas de `BossHints` recuerdan las acciones de combate. Los avisos siguen `InputGlyphs` y las reasignaciones. Abrir y cerrar Opciones o una novela desde pausa conserva la pausa anterior.

**Opciones → Controles** permite reasignar tecla y botón principales; Esc cancela y una asignación ocupada intercambia acciones. Las flechas, W/S, M y F1–F4 conservan sus usos reservados. Los nombres de mando mostrados por `KeyRemap` siguen el estilo PlayStation (✕ ○ □ △, L1/R1, Options, L3); `InputGlyphs.pad_color` da su color y `TextMarks` los pinta. `assets/fonts/PadSymbols.ttf` (subconjunto de DejaVu Sans) se añade como fuente de respaldo en `InputSetup`. `ui_accept` y `ui_cancel` reciben ✕ y ○ al arrancar, así que los menús responden al mando. **Avisos de teclas** permite Automático, Teclado o Mando; el modo automático observa el último dispositivo y descarta deriva pequeña del stick. Con controles táctiles visibles se utilizan sus nombres.

En historia, la pausa de arena permite **Repetir presentacion**; la práctica añade **Leer desenlace**. Boss Rush oculta la lectura narrativa. [Flujo narrativo](../gameplay/HISTORIA_FLUJO.md).

## Arsenal y presentación

Mantener E frente al taller abre `ui/equipment_shop.gd`: seis profesiones y fabricación de pala/trampas. La compra de profesión deja una herramienta para que un civil la recoja cuando haya plaza. El catálogo informa costes, existencias y requisitos.

`MenuSkin`, `MenuBackdrop` y `MenuFx` comparten el acabado de paneles; el menú carga `assets/ui/menu/ruinas_menu.png`. Las opciones de presentación controlan sus efectos.

## Resaltado de texto

`ui/text_marks.gd` mantiene el texto plano y las medidas del control mediante una capa `RichTextLabel`: teclas doradas `#ffce75`, objetivos turquesa `#47dacb`, peligros rosa `#dd6482` y hablantes violeta `#c6a0e8`. Escapa el contenido antes de aplicar BBCode.

Para un aviso fijo se puede usar `InputGlyphs.bind(etiqueta, "Mantén {interact}")` y `TextMarks.attach(etiqueta, "Mantén {interact}")`. Para texto variable, `TextMarks.attach(etiqueta)` sigue el contenido. `TextMarks.format_text(texto)` sirve para un `RichTextLabel` existente.

## Probar y validar

F5: abrir Opciones, cambiar una asignación, alternar teclado/mando y comprobar avisos. En colonia y jefe pausar, consultar controles y abrir/cerrar opciones. Iniciar una nueva campaña para comprobar que vuelve la flecha; los logros permanecen.

`menu_settings_test`, `menu_polish_test`, `key_remap_test`, `ui_guidance_test` y `text_marks_test` están en las 67 ejecuciones de `tests/run_all.gd`. Ejecutar con `tools/maintenance/validate.ps1`; registros en `build/validation/latest/`. No se mantienen recuentos históricos por comprobación ni avisos antiguos como si fueran resultados actuales.

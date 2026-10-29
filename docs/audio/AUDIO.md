# Audio actual

`systems/music_library.gd` define el repertorio activo: 21 OGG en `assets/audio/music/`. Hay pistas de menú, día por distrito, noche, aviso, victoria, derrota y nueve alternativas de jefe. Los temas de jefe se eligen de una bolsa compartida; no corresponden exclusivamente al nombre de su archivo.

`systems/game_sound.gd` administra las voces, la mezcla y los efectos. Los efectos están en `assets/audio/sfx/`, con su licencia CC0 de Kenney. Los controles de volumen se gestionan mediante los buses Master, Music y SFX y las opciones del juego.

Los OGG sintéticos `asedio.ogg` y `ruinas.ogg` y su generador anterior se retiraron porque el repertorio actual no los carga. Las herramientas vigentes de preparación e importación están en `tools/audio/`. El juego no depende de servicios de generación en línea.

Para probar: F5, comprueba los volúmenes en Opciones, inicia una colonia y entra a un jefe con F1. Victoria y derrota son cierres sin bucle; el resto de fondos musicales se repite según su configuración de importación.

El repertorio procede de la integración local de `origin/audio/musica-8bit`, commit `41e9613`. El informe separado de esa prueba se consolidó aquí para mantener una sola guía de audio.

[Herramientas](../../tools/README.md)

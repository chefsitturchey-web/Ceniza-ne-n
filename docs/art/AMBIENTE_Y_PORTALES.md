# Ambiente vivo y portales

`WorldAtmosphere` sitúa cuatro bocas de humo en la Periferia y utiliza los anclajes de `BackdropLife` para cinco en Fundición y dos en la Red. Mantiene quince emisores reutilizables (tres teselas), respeta las teselas reflejadas y usa la misma fórmula de parallax que `DistrictDepth`. Los poblados tienen otros tres emisores reutilizables sobre las salidas laterales del edificio posterior. Las tuberías cercanas purgan vapor por intervalos.

`WorldParticles` crea una textura de humo de 16 x 16 con alfa escalonado y filtro nearest. El humo crece, deriva y desaparece con una rampa. Compatibility, Android y web convierten el perfil GPU a CPU; otros renderers usan GPU con turbulencia leve. No se usa lectura de pantalla ni sombras de luces. La bruma se desplaza en dos capas. El polvo de las farolas sigue la intensidad interpolada del ciclo y las chispas aparecen con intervalos distintos por farola. La ceniza y los reflejos existentes siguen activos.

El portal enemigo es un repetidor de asedio, no una puerta que atraviese el jugador. Su shader dibuja un remolino cuantizado, borde neon y pulso de activacion. Las motas convergen hacia su centro, una luz sin sombras respira y un bucle sintetizado de un segundo suena en SFX con atenuacion espacial. Pedir refuerzos o destruirlo dispara una onda y sacudida a traves del `ImpactFeedback` existente, solo cerca del jugador. Restaurar un repetidor roto apaga tambien su luz y sonido.

Las reparaciones mezclan polvo y soldadura; las destrucciones tienen onda y humo persistente. Los impactos de combate comparten escombros y presupuesto global. Las arenas reutilizan vapor y bruma; el humo de las explosiones dura mas.

## Rendimiento y opciones

Se reutiliza **Reducir destellos** (`GamePreferences.reduced_flashes`): divide por tres el presupuesto de humo, ceniza, escombros y particulas de jefe; elimina chispas de farolas, estabiliza la luz y reduce las ondas. **Particulas** desactiva y oculta los emisores de inmediato, ademas de impedir nuevos escombros. El limite de escombros compartido sigue siendo 120 (40 reducido). Cada chimenea usa 18 particulas (6 reducido), cada salida de vapor 9 (3 reducido). La pausa detiene el mundo y sus bucles de audio.

## Probar

F5: observar las chimeneas al desplazarse; comprobar el cambio de luz al anochecer y atacar un portal con las tropas (F). Reparar una estructura para ver polvo y soldadura. F1 permite saltar a las arenas; Santa Caldera muestra humo y vapor junto a las rejillas. Alternar Particulas y Reducir destellos en las opciones existentes. Los controles de presentación se consultan también en la pausa.

La suite `tests/world_atmosphere_test.gd`, incluida entre las 67 ejecuciones de `tests/run_all.gd`, comprueba pool, textura, fallback, limites, apagado, compilacion del shader y restauracion de portales. Puede grabar con `--write-movie build/preview_ambiente/ambiente.avi --fixed-fps 30 --script res://tests/world_atmosphere_test.gd -- --capture` y deja cuatro PNG en `build/preview_ambiente/`. Usa un APPDATA aislado como el validador para proteger la partida.

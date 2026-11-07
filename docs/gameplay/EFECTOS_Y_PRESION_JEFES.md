# Marcha, impactos y presión de los cinco jefes

## Coberturas destructibles y cierre del combate

Las cinco arenas usan coberturas con resistencia: pilares de 130 puntos y cajas/barriles de 75. Las balas, embestidas e impactos fuertes las desgastan; muestran grietas, chispas y escombros. El fogonazo decorativo de un arma no causa daño. Al romperse, la cobertura pierde colisión y desaparece del mapa de navegación del jefe y sus refuerzos. El escombro permanece como señal visual; los límites de la arena se conservan.

La embestida contra una cobertura sigue abriendo una ventana de castigo al Recaudador, pero consume esa protección. El calor y los ataques de área de las demás arenas también erosionan los escondites mediante sus impactos. No se concede botín por destruirlos.

Se corrigió la invalidación de listas de ataques cuando una muerte dispara el final del combate: el Coro, los ataques secundarios y las cargas de los dispositivos recorren instantáneas y detienen la resolución al terminar la pelea. La comprobación dirigida reproduce una derrota en segunda fase con varias ondas, marcas, ataques secundarios o cargas pendientes; ya no intenta acceder a ataques eliminados por el final del combate.

En colonia, los fusileros y guardianes equilibran sus frentes por profesión aunque solo haya un cuartel; la asignación se guarda y se reajusta tras una baja. Las murallas exteriores se dibujan por delante de los pueblos, las fachadas son opacas y el Errante apoya sus pies en el suelo. Los saltos reales del Saltador permanecen intactos.

El avance real controla la cadencia de marcha. El Portador cenital conserva el montaje base de LibreSprite; el lateral, Prefecto y Madre incorporan clips posteriores de PixelLab y poses pintadas. Los PNG activos de los dos jefes finales no equivalen a sus ASE originales. [Formatos y reconstrucción actuales](../art/ARTE_COMBATE_ILUSTRADO.md).

Los tres robots aumentan su escala de 0,5 a 0,65: aproximadamente 88–92 unidades de altura frente a las 35 del Portador. Los anclajes siguen en el suelo. Las sombras y la galería respetan los nuevos tamaños.

## Ataques que se superponen

Los patrones principales siguen seleccionándose con `BossTactics`. `BossCombatEffects` añade una segunda capa independiente con posiciones fijadas al comenzar el aviso y límites por encuentro. No requiere plugins ni servicios externos durante el juego.

| Jefe | Nueva presión | Intervalo de fase 1 / fase 2 |
| --- | --- | --- |
| Recaudador | Golpe de presión de radio 118 / 142, superpuesto a garras, salvas o embestidas | 6,2 / 4,712 s |
| Santa Caldera | Dos erupciones escalonadas de radio 51 sobre la trayectoria prevista del jugador | 5,6 / 4,256 s |
| Coro Sumergido | Dos / tres rupturas de radio 54, además de sus ondas con abertura segura y marcas | 5 / 3,8 s |
| Prefecto | Dos / tres cortes eléctricos de semiancho 20 mientras encadena sus ataques principales | 4,4 / 3,344 s |
| Madre Cero | Alterna rupturas de radio 60 y dos / tres corredores eléctricos de semiancho 25, además del sabotaje de relés | 4 / 3,04 s |

Cada grupo secundario comienza con al menos 1,15 segundos de aviso; los impactos se escalonan 0,22 segundos. Se anticipa el desplazamiento observado del jugador, pero las marcas no lo persiguen después. Las coberturas bloquean el daño; los corredores se recortan al obstáculo encontrado. Un grupo pendiente no se duplica. El contador para crear otro grupo se detiene durante la anticipación cuerpo a cuerpo; por eso los intervalos de la tabla son tiempos base, no una periodicidad fija de reloj.

Las ventanas de núcleo expuesto eliminan los ataques secundarios pendientes y frenan su reinicio. El dispositivo de silencio del Coro también los cancela. La pausa y el cierre de la arena detienen la capa ofensiva. El núcleo sigue siendo la oportunidad de contraataque.

Los barridos principales alcanzan 118 unidades en el Recaudador y 108 en el Prefecto. Las embestidas tienen mayor anchura de contacto, representada en sus avisos. Tras una recuperación normal, el Prefecto pasa a aproximación durante 1 s, o 0,75 s en última guardia. Madre Cero usa intervalos de pulso base de 2,2 s en fase 1, 1,6 s en fase 2 y 1,2 s en último protocolo; el contador se detiene durante la anticipación cuerpo a cuerpo. Su exposición dura 6 s normalmente y 4,5 s en último protocolo.

## Presentación

- Barridos con estela curva, borde luminoso y chispas; embestidas con estelas laterales e impacto al terminar.
- Proyectiles con carcasa alargada, núcleo claro, cola y fragmentos al chocar, con paletas distintas por jefe.
- Rejillas con lenguas de fuego animadas; sonar con banda de presión y dientes, manteniendo su abertura segura.
- Rupturas con fisuras radiales, onda de presión, escombros y temblor breve de cámara.
- Humo continuo en los escapes de los tres robots, más denso en segunda fase.

Hay un presupuesto de 180 partículas y 32 impactos cosméticos por arena. Desactivar partículas conserva los avisos de peligro. La opción de destellos reducidos suprime el temblor y los destellos de impacto. La cámara recupera su posición al cerrar la arena.

## Probar

1. Ejecuta el proyecto con F5 y abre **F1 → práctica de jefes**. Compara cada jefe en sus dos fases; usa invulnerabilidad para observar los patrones completos y luego desactívala para probar la dificultad.
2. Enfrenta garras y embestidas a distintas distancias. Las marcas deben quedarse en su sitio después de comenzar el aviso. Usa una cobertura y comprueba las ventanas de núcleo expuesto.
3. En `levels/story/combat_animation_preview.tscn`, pulsa F6, elige **Caminar** y cambia entre las cuatro direcciones y las dos cámaras. **1–6** amplía el personaje; **0** vuelve al conjunto.
4. Comprueba partículas y destellos reducidos desde las opciones, y pausa durante un ataque.

`tests/boss_pressure_test.gd` verifica presión y presentación, incluida una simulación de los cinco cerebros contra un objetivo móvil y la coexistencia de sus patrones principales y secundarios. Con `-- --capture` guarda las cuatro tiras de marcha y diez capturas de combate en `.godot/combat-art/`. `tests/run_all.gd` registra 67 ejecuciones. Usar `tools/maintenance/validate.ps1`; registros en `build/validation/latest/`. La capa cuerpo a cuerpo de `recaudador.gd` se comprueba además en `boss_melee_test.gd`; sus perfiles no deben confundirse con los barridos de la máquina de estados anterior.

Referencias técnicas consultadas: [SLYNYRD: ciclo humano](https://www.slynyrd.com/blog/2024/5/24/pixelblog-50-human-walk-cycle), [partículas 2D de Godot](https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html) y [dibujo 2D de Godot](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html).

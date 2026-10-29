# Interfaz de vida en las arenas

El Portador muestra su vida roja, valor numérico y resistencia verde arriba a la izquierda. Un marco fino de metal trenzado rodea su vida, con remates discretos que dejan visible la resistencia. La vida del jefe ocupa una barra inferior de mayor grosor, con nombre, fase y marco ornamental pintado propio.

![Interfaz en Madre Cero: vida del Portador y daño reciente del jefe](../media/combat_hud_madre.png)

La franja dorada muestra el daño reciente: la vida real cambia inmediatamente, la estela espera 0,55 segundos para el jugador y 0,65 para el jefe, y después desciende hasta el valor actual. Curarse o restaurar valores desde F1 actualiza las barras. La animación se detiene durante la pausa y las conversaciones.

| Encuentro | Marco y emblema |
| --- | --- |
| Recaudador | Latón envejecido, garras hidráulicas, dientes de engranaje y detalles cian |
| Santa Caldera | Cobre ennegrecido, cuernos de horno y respiraderos ámbar |
| Coro Sumergido | Plata azulada, aletas de arpón, resonador y esmalte marino |
| Prefecto | Marfil y oro antiguo, alas de hoja y laureles |
| Madre Cero | Plata pálida, espinas, filigrana neuronal y cristales carmesí |

Un borde cian señala la ventana vulnerable del jefe. Los avisos tácticos permanecen arriba a la derecha. El botón de depuración se compacta a **F1** en las arenas para dejar libre el marco inferior.

La composición se inspira en la lectura de vida de Dark Souls; los marcos y símbolos son originales del proyecto, generados como arte original y montados en LibreSprite para su interfaz industrial. Se consultó la [galería oficial de Dark Souls Remastered](https://www.darksouls.jp/remastered/movieandimages.html); no se copiaron sus recursos gráficos.

## Probar

Ejecuta F5, abre F1 y entra en cualquiera de los cinco jefes. Recibe un golpe, esquiva para consumir resistencia y daña al jefe. Compara las fases y abre el núcleo. Pausa durante una estela para comprobar que se congela.

`tests/boss_hud_test.gd` comprueba 66 condiciones: daño real inmediato, retención y descenso de las estelas, pausa, curación, resistencia, fase, vulnerabilidad, cinco paletas y separación del botón F1. Con `-- --capture` guarda cinco capturas en `.godot/combat-art/`. La batería completa contiene 41 suites. Los seis marcos tienen PNG y fuentes ASE en `assets/ui/frames/`; sus ventanas transparentes se verifican también en `environment_depth_test.gd`. [Fondos, capas y proceso de arte](../art/FONDOS_EN_CAPAS.md).

El error de carga de `CoroSumergido` se resolvió retirando un espacio situado antes de las tabulaciones de su línea 109; no requería cambiar sus mecánicas.

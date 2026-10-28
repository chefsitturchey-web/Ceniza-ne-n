# Equipo automático y evoluciones

La clínica conserva la pestaña Implantes y añade Equipo. Cada mejora de equipo o pasiva cuesta un punto neuronal; sigue siendo un punto por cada seis bajas de la colonia. El dron inicial es gratuito. Los implantes anteriores no cambian y el daño 50, la velocidad 220 y los tiempos 10/10/60 del Inspector se conservan.

| Módulo | Ataque | Pasiva compatible | Evolución |
|---|---|---|---|
| Dron centinela | Disparo dirigido; +2 daño por nivel posterior al primero | Óptica táctica: +25 alcance | Enjambre: segundo dron con disparo al 65% del daño |
| Emisor Tesla | Descarga eléctrica corta; atraviesa escudos del Blindado | Batería auxiliar: +20 alcance | Tormenta: hasta cuatro objetivos distintos, caída de daño al encadenar |
| Disco orbital | Daño cercano de área, hasta tres enemigos por activación | Rodamiento magnético: +8 alcance | Corona de acero: cuatro discos visuales, más alcance y hasta seis objetivos |

Hay cinco niveles por equipo y dos ranuras automáticas como máximo. Desbloquear un equipo lo instala automáticamente si hay una ranura libre. Con dos ocupadas, retira uno antes de equipar otro; no se permite retirar el último. Las pasivas de esta entrega se compran una vez y permanecen instaladas.

La evolución exige nivel cinco, la pasiva compatible y un núcleo de enlace. La última unidad de cada oleada lleva una marca ámbar y entrega un núcleo al ser derrotada; no aumentan su vida ni su daño. La evolución consume un núcleo y no se puede comprar dos veces. Ejemplo: cuatro puntos para llevar el dron de nivel 1 a 5, uno para Óptica táctica y un núcleo para Enjambre. Un equipo desbloqueado desde cero necesita un punto adicional.

Los módulos viajan a la arena. Respetan distancia, coberturas y escudo del Recaudador: sigue siendo necesario buscar la ventana de núcleo expuesto. Como allí hay un único jefe, Tormenta concentra un 40% adicional en ese objetivo; Enjambre añade un 65%. Los discos siguen siendo de corto alcance. Los módulos no atacan repetidores ni sustituyen las construcciones.

## Cómo probar

1. F5 → Nueva partida o Continuar. Defiende la colonia para recuperar puntos y un núcleo al terminar una oleada.
2. De día, mantener E en la clínica. Cambiar a Equipo con ratón o las pestañas del mando/teclado; el listado permite desplazarse y sigue el foco.
3. Comprar una especialización, su pasiva y los niveles necesarios. Evolucionar cuando la receta esté completa. Las compras y cambios de ranura actualizan el guardado de día.
4. Comprobar Tesla contra un Blindado y el disco rodeado de enemigos. Viajar al Recaudador para probar los ataques automáticos contra su núcleo y detrás de coberturas.

## Verificación y correcciones

`tests/modules_test.gd`: 38 comprobaciones de presupuesto, recetas, doble gasto, dos ranuras, daño eléctrico real, cadena de objetivos, área limitada, guardados inválidos, ida/vuelta y combate en arena. La prueba gráfica opcional `-- --capture` guarda `.godot/equipo-clinica.png`; se revisó la captura. La suite completa suma 19 pruebas y conserva las simulaciones de colonia sin mejoras: 128.6 s sin apoyo y 240.5 s con apoyo.

Se corrigieron nodos huérfanos de escenas de enemigos: ahora los componentes se crean en `_ready`, no en inicializadores que Godot puede ejecutar al reasignar scripts en escenas heredadas. La luz ambiental pertenece al nodo View, evitando una adición diferida a un distrito que ya pudo liberarse. Las suites de módulos y enemigos cierran sin avisos de esos nodos. Sigue pendiente el aviso de referencias al cerrar el comprobador estático descrito en `MENU_Y_OPCIONES.md`.

Los datos están en `data/modules/`, separados de la ejecución. Los guardados sin el bloque de equipo reciben el dron base sin gastos inventados. No se han implementado todavía las otras armas, el lanzaminas, el intercambio de pasivas ni la campaña de distritos 2–4 y sus jefes; las recetas de esta entrega siguen el primer subconjunto del GDD.

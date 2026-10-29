# Equipo automático y evoluciones

Recoge datos neuronales en el mundo para subir de nivel: el tiempo se detiene y eliges una de tres mejoras de armas, pasivas o implantes. La clínica sirve para consultar y configurar lo obtenido. El dron inicial es gratuito; el personaje conserva daño 50 y velocidad 220. [Reglas actuales y revisión del GDD](../design/REVISION_GDD_KINGDOM_SURVIVORS.md).

| Módulo | Ataque | Pasiva compatible | Evolución |
|---|---|---|---|
| Dron centinela | Disparo dirigido; +2 daño por nivel posterior al primero | Óptica táctica: +25 alcance | Enjambre: segundo dron con disparo al 65% del daño |
| Emisor Tesla | Descarga eléctrica corta; atraviesa escudos del Blindado | Batería auxiliar: +20 alcance | Tormenta: hasta cuatro objetivos distintos, caída de daño al encadenar |
| Disco orbital | Daño cercano de área, hasta tres enemigos por activación | Rodamiento magnético: +8 alcance | Corona de acero: cuatro discos visuales, más alcance y hasta seis objetivos |

Hay cinco niveles por equipo y dos ranuras automáticas. Una nueva arma se ofrece si queda ranura; puedes cambiar equipo ya obtenido en la clínica. Hay seis pasivas de cinco niveles y cuatro espacios equipados. Puedes retirar o activar pasivas en Equipo sin perder sus niveles. Las pasivas adicionales son Bobina de atracción, Condensador de impacto y Recuperador cinético.

La evolución exige nivel cinco, pasiva compatible equipada y núcleo de enlace. La última unidad marcada de una oleada deja un cofre que debes recoger: ofrece evoluciones válidas, mejora normal o guardar el núcleo. La evolución consume uno y no se compra dos veces. Después puedes cambiar la pasiva sin perder la evolución. Los jefes también garantizan un núcleo.

Los módulos viajan a la arena. Respetan distancia, coberturas y escudo del Recaudador: sigue siendo necesario buscar la ventana de núcleo expuesto. Como allí hay un único jefe, Tormenta concentra un 40% adicional en ese objetivo; Enjambre añade un 65%. Los discos siguen siendo de corto alcance. Los módulos no atacan repetidores ni sustituyen las construcciones.

## Cómo probar

1. F5 → Nueva partida o Continuar. Recoge datos, sube de nivel y elige una carta. Recoge el cofre marcado que deja una élite.
2. De día, mantener E en la clínica. Cambiar a Equipo con ratón o las pestañas del mando/teclado; el listado permite desplazarse y sigue el foco.
3. Desarrolla arma y pasiva mediante subidas de nivel. El cofre ofrece evolución cuando la receta esté completa. Puedes configurar lo ya obtenido en la clínica.
4. Comprobar Tesla contra un Blindado y el disco rodeado de enemigos. Viajar al Recaudador para probar los ataques automáticos contra su núcleo y detrás de coberturas.

## Verificación y correcciones

`tests/modules_test.gd`: 38 comprobaciones de presupuesto, recetas, doble gasto, dos ranuras, daño real, guardado y combate en arena. La revisión del GDD añade 67 comprobaciones integradas y la batería completa suma 26 casos. Las simulaciones también recogen experiencia y eligen mejoras.

Se corrigieron nodos huérfanos de escenas de enemigos: ahora los componentes se crean en `_ready`, no en inicializadores que Godot puede ejecutar al reasignar scripts en escenas heredadas. La luz ambiental pertenece al nodo View, evitando una adición diferida a un distrito que ya pudo liberarse. Las suites de módulos y enemigos cierran sin avisos de esos nodos. Sigue pendiente el aviso de referencias al cerrar el comprobador estático descrito en `MENU_Y_OPCIONES.md`.

Los datos están en `data/modules/`, separados de la ejecución. Los guardados anteriores conservan su presupuesto y equipo. Hay tres distritos y cambio de pasivas; siguen pendientes las otras armas del catálogo y los distritos/jefes restantes, detallados en la auditoría del GDD.

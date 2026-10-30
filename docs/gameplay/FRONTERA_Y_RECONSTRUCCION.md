# Frontera y reconstrucción

Esta guía describe las reglas actuales de colonia y sustituye las instrucciones anteriores que empezaban con un núcleo construido y cuatro defensas disponibles.

## Cinco distritos más amplios

El corredor normal pasa de 3.200 a **14.400 píxeles**: 4,5 veces el ancho. Se amplían suelo, colisiones, cámara y límites de guardado. Las arenas de los cinco jefes conservan sus dimensiones, arte y control.

| Distrito | Distribución y obstáculos | Rescate / relé / transporte inicial |
|---|---|---|
| Periferia | Corredor ferroviario, solares a distintas distancias y vagones descarrilados | -2350 / +3450 / -4200 |
| Fundición | Terrazas de escoria, avance oriental más estrecho y rejillas calientes | -3250 / +4550 / -5000 |
| Barrio inundado | Diques asimétricos, conductos inundados y charcos | -3550 / +4950 / -5250 |
| Ciudadela | Avenidas protegidas por barricadas del Consejo | -3100 / +4700 / -5600 |
| Red | Solares separados por raíces de fibra y portales escalonados | -3500 / +5000 / -5900 |

Cada zona ofrece 16 parcelas de instalaciones, 12 murallas exteriores y al menos 14 emplazamientos centrales o avanzados de defensa. Las posiciones izquierdas y derechas son diferentes. La planificación reserva espacio alrededor de talleres, transporte, operaciones y defensas para que una interacción no tape otra. Los suministros sueltos de chatarra se recogen al pasar sobre ellos. Los portales interiores bloquean las franjas exteriores hasta destruirlos; los repetidores finales están cerca de los nuevos extremos. Las incursiones alcanzan el perímetro actual a través de conductos sin sellar, sin obligar a esperar a que una oleada recorra todo el mapa.

## Empezar desde cero

1. Llegas con un constructor y un recolector, sin núcleo ni edificios propios operativos. Las dos baterías cercanas proporcionan las primeras piezas. Mantén E para extraer; cada extracción tarda 2,5 segundos.
2. Reúne **12 piezas y 20 de chatarra**. Mantén E en el cimiento central para encargar el núcleo. Un constructor debe trabajar 24 segundos; no aparece instantáneamente. Hasta encenderlo, el reloj de asedios y la economía del recolector esperan.
3. El núcleo de nivel 1 permite las dos murallas centrales, generadores, cuarteles y profesiones básicas. Las torretas siguen bloqueadas.
4. Encarga con E el despeje de una parcela de generador: cuesta 5 de chatarra. Un constructor viaja y trabaja, siempre que la franja esté abierta y no haya enemigos cerca. El despeje dura entre 18 y unos 53 segundos según distancia y distrito, entrega 4 piezas al depósito y 6 de chatarra y libera ese solar permanentemente.
5. Construye el generador y las dos murallas. Con **60 de chatarra y 10 piezas** puedes encargar el núcleo de nivel 2. No se exigen torretas para desbloquearlas. Se habilitan mejoras de defensas, apoyo y transporte.
6. El nivel 3 cuesta **120 de chatarra y 18 piezas** y exige sobrevivir una noche y tener dos instalaciones. Abre las mejoras avanzadas. Cada nivel conserva su propio diseño.

Las defensas necesitan 16 segundos de trabajo y las instalaciones 24, además del desplazamiento del constructor. Dos trabajadores pueden colaborar en algunas tareas. Los solares alejados requieren núcleo de nivel 2. No se cobra una construcción bloqueada por escombros o requisitos.

La generación crece con el núcleo: cada generador aporta 2/4/6 de capacidad en niveles 1/2/3, y el núcleo gana 4 de capacidad adicional por mejora. El consumo sigue importando al ampliar el perímetro; T permite apagar torretas que ya no necesitas detrás del frente.

## Mochila, depósito y piezas caídas

La mochila admite **24 piezas**. Al recuperar más, el exceso cae: cada pieza tiene un 25 % de probabilidad de romperse. Las que sobreviven quedan en montones visibles; E las recoge si queda espacio. La extracción no se cancela por llevar la mochila llena: conviene descargar antes de agotar un objeto.

Al volver a menos de 60 píxeles de un núcleo encendido, las piezas pasan automáticamente al depósito. Las recetas utilizan primero las reservas y después lo que llevas encima. El HUD muestra **P llevadas/24 +almacenadas**, con un icono de mochila. Piezas, depósito, montones, solares y trabajos en curso se guardan.

El tren transporta las piezas que llevas en la mochila al siguiente distrito. Las reservas del depósito se quedan abasteciendo la colonia anterior.

Los checkpoints anteriores se migran: se conservan los edificios, las primeras parcelas y el botín ya recogido; el inventario antiguo que exceda 24 pasa al depósito sin romperse. Las nuevas parcelas se añaden libres de edificios. La posición de algunas fortificaciones cambia con el nuevo trazado del distrito. La copia `.anterior` del sistema de guardado sigue protegiendo documentos inválidos.

## Dificultad e historia

Los días permiten 360–480 segundos de preparación según distrito. El trabajo es más lento, el territorio obliga a planificar viajes y las oleadas tienen menor intervalo entre apariciones. En las zonas posteriores, la vida de los invasores crece un 18 % por distrito y su daño un 8 %, con valores fijos por capítulo; estas reglas se aplican a instancias de colonia y no a jefes.

Hay un comienzo de novela visual incluso al abrir directamente la escena del distrito. Los cinco capítulos reciben diálogos propios al encender un núcleo y recuperar el primer solar. Son **40 conversaciones** contando las 30 existentes, con retratos, transiciones y repetición en L. El objetivo del HUD guía desde las piezas iniciales hasta rescate, relé, escolta, portales, tren y jefe. El último combate conserva el desenlace de la campaña; no se promete una duración de cuatro horas sin medirla con jugadores.

## Arte y comprobación

Ratas, trampas, baterías, antenas, piezas y mochila tienen nuevos píxeles dibujados y exportados **dentro de LibreSprite**, mediante `tools/art/libresprite_frontier.js`. La rata tiene ocho fotogramas; la trampa tiene posiciones abierta, cerrada y activada. Los cadáveres reutilizan la pose final de caída de las profesiones aprobadas, con descomposición visual. Coches, cajas y bobinas utilizan el arte industrial existente.

Los editables están en `assets/characters/pests/sources/`, `assets/world/salvage/sources/` y `assets/ui/icons/frontier/sources/`. No se han reemplazado los sprites aprobados del Portador o de los jefes. `tools/art/build_frontier_art.py` preserva fuentes existentes y permite generar únicamente un recurso nuevo con `--only`.

Prueba con F5 → Nueva partida. F1 conserva las prácticas de jefe. La validación de este bloque se limita a `frontier_progression_test`, compilación de scripts y tácticas de los cinco jefes. Las capturas revisadas se generan con el renderizador real mediante `validate.ps1 -Suite frontier_progression_test -Capture`; los archivos quedan en `build/validation/latest/` y no se incluyen en Git. La batería histórica completa no se ha vuelto a certificar: sus simulaciones que presuponen cuatro cimientos y núcleo inicial requieren actualizarse a estas reglas.

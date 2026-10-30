# Integración de mecánicas de invasión

Se integra `origin/feature/mecanicas-invasion` (`339e1e1`) en `prueba/audio-8bit`, partiendo de `26fe467`. La referencia local `backup/audio-8bit-antes-invasion` conserva el estado anterior. No se publica en remoto ni se modifica `main`.

## Qué incorpora

- Restos industriales: mantener E durante 2,5 segundos extrae piezas y chatarra. Cada objeto tiene cargas limitadas y posiciones con variación por partida.
- Taller junto al de profesiones, en x=-495 y x=-465: pala por 4 de chatarra y 8 piezas; cada trampa por 15 de chatarra y 6 piezas. Hay dos emplazamientos de trampa, en x=-260 y x=260.
- Los trabajadores tienen 60 de vida y pueden morir junto a enemigos. Sus cadáveres se descomponen con los días. Desde la segunda etapa contaminan y atraen ratas.
- E reporta un cadáver. Con una pala, un constructor lo entierra de día y en terreno seguro; tarda tres segundos tras llegar.
- Las ratas buscan torretas activas y cortocircuitan su cableado. Las trampas las capturan y se recuperan en seis segundos. E repara una máquina averiada si queda capacidad energética.
- Encargos y construcción nocturna, retirada ante amenazas y desplazamiento de trabajadores ociosos.
- Marcha de colonia de 100 px/s; Shift multiplica por 1,5 y consume 5 de resistencia por segundo. Esquiva de colonia por 20 y con tres segundos entre usos.
- Corredor, Saboteador y Saltador más rápidos en apariciones de colonia. El HUD muestra las piezas.

## Compatibilidad con los avances actuales

Los cuatro conflictos de texto estaban en `periphery.tres`, `player.gd`, `topdown_player.gd` y `civic_system.gd`. Se conserva íntegro el controlador cenital anterior, junto a scripts, arenas, arte, efectos, fondos y marcos de los jefes. Su movimiento sigue a 220 px/s y su esquiva cuesta 30, sin el enfriamiento de colonia. Las nuevas velocidades de enemigos se aplican a instancias de colonia, conservando los recursos compartidos con arenas.

Los soldados derrotados siguen perdiendo su profesión y regresando como civiles: no se crea además un cadáver de la misma persona. La muerte permanente nueva corresponde a los trabajadores. Antes de tomar el tren debe quedar un constructor y un recolector, para que el relevo de campaña sea válido. El aviso permite reclutarlos antes de partir. El laboratorio F1 conserva sus accesos de práctica a los cinco jefes.

Se conservan la compra nocturna de herramientas y los cambios locales del usuario en `docs/GUIA_ARTE.md`. Los objetos nuevos utilizan representaciones geométricas provisionales de la rama; esta integración no sustituye el arte aprobado.

## Correcciones y guardados

Los checkpoints de día ahora incluyen piezas, pala, cargas y posiciones de objetos, cadáveres, trampas, ratas, cortocircuitos, heridas y población real. Cargar no repone botín ni resucita trabajadores. Se siguen admitiendo checkpoints antiguos de versión 1. Piezas, pala, restos y trampas pertenecen al distrito; el tren conserva el traslado existente de campaña.

Se corrigen la carga de puntos de recogida desde los recursos, interacciones tapadas por edificios, duración real de extracción, tinte del sprite visible al contaminarse, reparación sin energía, ratas con objetivo desaparecido y captura de ratas que cruzan trampas en un fotograma largo.

## Cómo probar

Abre `project.godot`, pulsa F5 y empieza una colonia. Usa Shift, recoge piezas con E y fabrica pala o trampas en el taller izquierdo. F1 permite preparar días y amenazas; la práctica no sobrescribe el checkpoint normal. Prueba también los cinco jefes desde F1.

`invasion_integration_test` comprueba extracción, persistencia, datos inválidos, contaminación, entierro, energía, plagas, bajas, guardados antiguos y separación del combate de arena. Ejecuta las comprobaciones con `tools/maintenance/validate.ps1`; los registros quedan en `build/validation/latest/`.

Validación de la integración: 42 suites completas sin fallos, 70 comprobaciones en la nueva suite y 67 comprobaciones adicionales de `gdd_foundations_test` sin fallos. Se compararon 230 archivos protegidos con los blobs del commit anterior: sin diferencias. Son pruebas automáticas; los nuevos objetos provisionales todavía necesitan una revisión artística en pantalla.

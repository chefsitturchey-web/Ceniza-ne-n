# Siluetas mecánicas del asedio

Blindado, Saltador y Ariete tienen presentaciones propias dibujadas por piezas en `components/machine_rig.gd`, con la paleta y el tamaño del juego. Se redondean las articulaciones a píxeles y se conserva el filtro nearest. Son diseños originales del proyecto en código, no nuevas hojas PNG producidas por un generador.

- Blindado: cabeza hundida, pecho ancho, hombros de acero, piernas cortas y escudo frontal achaflanado con remaches, sensor y desgaste.
- Saltador: torso bajo en cuña, patas articuladas, muelles visibles y tobera posterior. Comprime el cuerpo durante la anticipación y enciende la tobera al saltar.
- Ariete: bloque pesado con contrapeso, cilindro hidráulico, planchas oxidadas y cabeza de impacto. La pieza frontal conserva el retroceso de preparación existente.

Las placas usan contorno oscuro, metal de tres tonos, tornillos y marcas de desgaste. El sensor rosa sigue identificando una máquina enemiga; el ámbar señala peligros y la unidad que transporta un núcleo. Marcha, anticipación, daño y destrucción son presentación: no alteran las reglas, vida, alcance ni temporizadores de ataque.

Los sprites y animaciones anteriores siguen incluidos y activos para conservar tiempos de destrucción y recursos. El ajuste `detailed_silhouette` de la entidad permite volver a la presentación anterior desde el Inspector. No se reemplazó ningún PNG del usuario. Los enemigos con rig no dibujan el reflejo de su sprite oculto; esto evita mostrar una silueta antigua en el suelo. Queda pendiente un reflejo de las piezas nuevas si se desea ampliar ese efecto.

## Comprobación

F5 → Nueva partida: aparecen Blindado y Saltador desde la segunda noche, y Ariete desde la tercera. El escudo gira hacia el frente del Blindado; atrae al Saltador a una muralla y observa su compresión/salto. El Ariete prepara el pistón antes de golpear.

`tests/machine_rig_test.gd`: 16 comprobaciones de modelos diferenciados, anclajes, filtro, conservación de sprites, independencia entre animación y reglas, destrucción y alternativa del Inspector. Con `-- --capture` genera `.godot/maquinas-siluetas.png`, una comparativa ampliada de los tres modelos; se revisó en OpenGL. La suite completa suma 20 pruebas y conserva las dos simulaciones de balance sin mejoras.

Estos modelos son una presentación animada funcional para el prototipo. Siguen pendientes las animaciones verticales del Portador y la producción artística final que decida el equipo. Los prompts de sprites maestros y entregas externas permanecen en `GUIA_ARTE.md` y `REVISION_Y_AUDIO.md`.

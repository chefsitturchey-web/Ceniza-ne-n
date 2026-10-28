# Pulido de la demo: torreta, animaciones y recorrido completo

## Qué cambió

- Torreta: el sprite original se dibuja como pedestal y cabezal separados. El cabezal patrulla en reposo, sigue al enemigo, gira al frente interior si lo supera, se eleva ante blancos altos y recibe retroceso al disparar. El pedestal y las colisiones permanecen fijos. Rayo y fogonazo salen de la boca del cañón articulado. Daño, alcance, costes y cadencia se conservan, incluida la sobrecarga.
- Portador en arena: piernas y brazos se articulan al caminar al norte/sur a partir de las vistas originales. Hay respiración en reposo, ataque lateral con las animaciones existentes y caída/desvanecido al morir. La hoja opcional `directional_frames` sigue teniendo prioridad si se proporciona. No se generaron ni sobrescribieron PNG; es animación por piezas en ejecución, no una nueva hoja dibujada cuadro por cuadro.
- Colonia: el recuperador usa su animación de trabajo cuando alcanza la chatarra; su carga oscila al caminar. Constructores y recuperadores tienen pequeñas partículas de trabajo. El núcleo muestra luces de actividad y respeta la opción de reducir sacudidas.
- Equipo y sonido: el dron es visible y oscila también en la arena; Tesla muestra su bobina. Los disparos automáticos tienen origen visual coherente. Se añadieron impactos de la hoja y pasos discretos reutilizando el sonido metálico CC0 existente con menor volumen.
- Inicio: Nueva partida muestra una explicación con el reloj detenido. Comenzar devuelve el control sin gastar resistencia por una pulsación compartida con la interfaz. Se preservan velocidad 220, daño 50 y ciclo 10/10/60.
- Objetivos: el HUD indica encargar defensas, proteger las obras, destruir antenas, esperar el tren y viajar de día. Mantiene la presentación compacta y las estadísticas detalladas en pausa.
- Pausa y finales: Continuar tiene botón y foco para mando. Las opciones funcionan también durante el jefe y devuelven a la misma pausa. La derrota de la colonia ofrece Reintentar y Menú. El final del distrito dice que la demo está completada y vuelve al menú; ya no reinicia otro Distrito 1 como si avanzase la campaña. F6 en la arena dispone de reintento y salida tras perder o ganar.
- Guardado: se escribe un archivo temporal y se sustituye el checkpoint tras completar la escritura. Una escritura fallida conserva el archivo anterior. Antes de viajar se guarda la preparación del día, incluidas las antenas y el tren. Cerrar un panel o reanudar no dispara una esquiva por la pulsación de aceptar.

## Cómo probarlo

1. F5 → Nueva partida → leer la explicación → Comenzar. Con A/D recorre los cuatro marcos y mantén E para encargarlos. Las cuatro obras cuestan las 90 unidades iniciales de chatarra.
2. Durante la noche observa ambas torretas. Deben apuntar hacia las máquinas y disparar con retroceso; al pasar una máquina hacia el núcleo, el cabezal puede cambiar de lado. Q acelera la cadencia en tu frente.
3. Mira al recuperador en el punto de recolección y al volver cargado. Encarga reparaciones para ver al constructor trabajar.
4. Destruye las antenas y viaja. En la arena mueve con WASD, ataca con J y esquiva con Espacio. Comprueba caminar vertical, ataque, dron, pausa, opciones y vuelta al menú.
5. Tras derrotar al Recaudador aparece el final de esta demo. La campaña de los otros distritos sigue fuera de este bloque.

## Comprobaciones

`tests/polish_integration_test.gd` añade 36 comprobaciones: reloj de introducción, control al cerrar, foco y botón de pausa, objetivos, daño real de torreta, origen del disparo, seguimiento de altura/frente, retroceso, destrucción, sobrecarga, recolección, guardado fallido, preparación antes del viaje, animación vertical, ataque, opciones del jefe y navegación real al menú sin arena huérfana. La prueba del Recaudador amplía la cobertura de los finales de la escena independiente.

`tests/fresh_colony_simulation.gd` empieza con las estructuras sin construir. El jugador automatizado se desplaza, mantiene la interacción para pagar/encargar y después ayuda en combate y reparación. En la configuración actual encarga las cuatro obras en 7.1 segundos, construye las cuatro y supera el asedio de tres noches con núcleo 300 en 240.5 segundos. No cambia estadísticas ni regala recursos; desactiva el requisito de jefe solo para terminar esta prueba de colonia. Esto comprueba la ruta inicial y el funcionamiento de los sistemas, no la dificultad para una persona nueva ni una partida completa jugada por humanos.

`tests/run_all.gd`: 22 suites, 0 fallos detectados. Se mantienen las referencias anteriores de 128.6 s sin ayuda y 240.5 s con ayuda. Continúa el aviso de referencias al cerrar el comprobador estático, documentado en `MENU_Y_OPCIONES.md`; las pruebas de ejecución de este bloque cierran sin ese aviso.

Captura gráfica opcional:

```text
godot --path . --script res://tests/polish_integration_test.gd -- --capture
```

Produce secuencias de torreta y marcha vertical, introducción y final en `.godot/pulido/`. Se revisaron capturas con OpenGL en GTX 1070 y se generaron las vistas animadas `torreta-animada.gif` y `marcha-vertical.gif`. Son material de validación local y están fuera de los commits.

Referencias para las transformaciones y el dibujo por piezas: [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) y [Node2D](https://docs.godotengine.org/en/stable/classes/class_node2d.html), documentación oficial de Godot.

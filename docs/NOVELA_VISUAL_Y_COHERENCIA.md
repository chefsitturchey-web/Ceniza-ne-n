# Novela visual y coherencia de estructuras

## Cómo comprobarlo

- En Godot, abre `levels/story/novel_preview.tscn` y pulsa **F6**. Después de cerrar la primera escena, elige capítulo y conversación. La galería permite revisar las 30 escenas sin modificar la partida.
- En una **Nueva partida**, cierra primero las instrucciones: aparecerá la llegada al distrito. Rescates, relés y convoyes presentan conversaciones al completar la operación. El viaje y la victoria presentan el encuentro y la despedida del jefe.
- **E, Enter, Espacio o clic** completan el texto y después avanzan. **Anterior** permite releer. **Omitir / Esc** cierra la escena. El mundo permanece pausado mientras lees. En **L → Ver conversación** puedes repetir las escenas desbloqueadas.
- Para revisar las construcciones y sus tres niveles, abre `levels/zones/fortress_playground.tscn` y pulsa **F6**.

## Dirección visual

La referencia `docs/references/diseñoejemplo.jpg` se pudo abrir desde el disco. Su lenguaje es manga de tinta: contorno negro variable, sombras duras, trama fina en ropa y metal, rostro angular y extremidades mecánicas muy detalladas. Los retratos nuevos trasladan esos rasgos a color, con sombras por planos y acentos cian/ámbar. Los personajes son originales del proyecto; la referencia orienta el acabado, sin reproducir su personaje.

El reparto ilustrado incluye Portador, Mara, Ivo, Vera, Nox, ECO, el Prefecto y MADRE CERO. Hay foco en quien habla, movimiento suave, texto progresivo y fundidos. La opción de destellos reducidos reduce también el movimiento de los retratos. No hay voces grabadas ni sincronización labial.

Las estructuras del mundo mantienen pixel art lateral: acero gris oscuro, cobre oxidado, luz cian y ámbar, tornillos, tuberías y bases industriales. El núcleo tiene tres diseños distintos. Las torretas separan pedestal y cabeza móvil; una unión mecánica cubre el pivote. Murallas estrechas y edificios comparten el plano del suelo. El refugio se desplazó para evitar superponerlo con la torreta derecha.

Los atlas tienen transparencia y límites medidos con `tools/art/measure_art.py`. Sus recortes se guardan en `data/art_bounds.gd` y `.json`. La fortaleza y los edificios civiles usan cortes de fila explícitos porque la generación no produjo filas de idéntica altura. No sustituirlos por divisiones uniformes. Las texturas anteriores se conservan, aunque las nuevas sustituyen su uso en estas estructuras.

## Especificaciones para nuevos recursos

**Retrato:** ilustración manga a color, medio cuerpo, personaje original posapocalíptico industrial; contorno de tinta negro de grosor variable, sombras de cel con bordes duros, hachurado selectivo, rostro expresivo, mecánica funcional con tornillos y cables; paleta carbón/acero/cobre con acentos cian y ámbar; fondo transparente, sin texto ni marcos; mantener rostro, ropa y accesorios entre expresiones. Evitar acabado pictórico suave. Usar los retratos manga actuales y la referencia de tinta como guía.

**Estructura:** sprite de pixel art lateral ortográfico para CENIZA NEÓN; acero gris oscuro, óxido de cobre, tuberías, remaches y luces cian/ámbar; base horizontal completa al borde inferior, sin suelo pintado ni sombra separada; fondo transparente. Escala de puerta acorde al Portador. Para cada mejora conservar materiales y silueta reconocible, añadir refuerzos y equipo. Una cabeza de torreta lleva únicamente arma y articulación, sin patas ni otro pedestal. Usar `industrial_atlas_v2.png` y los atlas `coherent_*` como referencias.

## Alcance narrativo

Las conversaciones desarrollan el guion de los cinco capítulos existentes; no añaden decisiones ramificadas ni garantizan cuatro horas de juego. Releer escenas no concede experiencia ni recursos. Las escenas vistas se incluyen en el guardado; las partidas anteriores siguen siendo compatibles. La despedida del jefe no vuelve a guardar la colonia anterior sobre el punto de llegada al próximo distrito.

## Validación

`tests/visual_novel_test.gd` comprueba pausa, foco, entrada de controles, fundidos, repetición desde el diario, escenas vistas, las 30 escenas sin desbordamiento de texto, ausencia de recompensas duplicadas, viaje al jefe, despedida, conservación del punto de llegada y galería F6. `tests/fortress_progression_test.gd` comprueba niveles, desbloqueos y anclaje de las estructuras. `tests/run_all.gd` ejecuta las 38 suites del proyecto. Las capturas y registros quedan fuera de Git.

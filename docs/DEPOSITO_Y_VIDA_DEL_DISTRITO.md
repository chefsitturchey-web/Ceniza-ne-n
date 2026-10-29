# Taller, pasos y depósito del Recaudador

## Probar

- **F5:** recluta supervivientes y compra herramientas en el taller. Si falta cuartel, generador, puesto médico o una plaza, el puesto y el aviso sobre el taller explican la espera. Las herramientas reservadas se conservan y se recogen al quedar disponible la profesión.
- Varias personas reparten las herramientas disponibles. Los tiradores y guardianes comparten las plazas del cuartel. Quienes esperan empleo se reúnen cerca del taller durante el día y se refugian por la noche.
- También se recogen herramientas de noche cuando las murallas protegen el taller y no hay enemigos cerca. Ampliar el perímetro hasta el taller permite equipar refuerzos sin esperar al amanecer.
- **F6 en `levels/expedition/recaudador_arena.tscn`:** practicar el primer jefe en el depósito ferroviario. La plataforma, las paredes físicas y las balas comparten un contorno de doce vértices. Las otras cuatro arenas también tienen perímetros poligonales.
- **F6 en `levels/zones/fortress_playground.tscn`:** mirar las chimeneas, la vía elevada y los extractores del fondo de la periferia. El humo y los ventiladores están anclados al dibujo. Hay tránsito ferroviario, luces suaves y agua animada.

![Depósito del Recaudador](media/recaudador_actual.png)

## Animación y reglas

La marcha ahora avanza sus fotogramas por distancia: una zancada normal recorre 28 unidades. Los fotogramas de render que ocurren entre dos actualizaciones de movimiento mantienen el apoyo del pie, en lugar de alternar marcha y reposo y reiniciar la secuencia. Al detenerse vuelve la respiración normal. El transporte de carga y la huida tienen cadencias propias.

El Recaudador tiene chasis, orugas, garras, escudo, reactor, compuerta con textura y turbina separados. Las orugas siguen el desplazamiento; la turbina gira; la garra extiende su pistón y la compuerta descubre el reactor durante el aturdimiento. Sus señales, daños, ventanas de ataque y colisiones conservan las reglas de combate. Los fragmentos de destrucción usan la escala y orientación de cada pieza.

La arena representa una estación de cobro junto al canal: grúa suspendida, carga, bombas, vapor, vías y balizas. La maquinaria decorativa queda fuera del espacio de combate; las seis coberturas físicas tienen arte industrial y tamaño correspondiente. El agua se mueve alrededor del muelle. La cámara muestra el contorno y las coberturas.

El fondo lateral anterior tenía animaciones calculadas, pero no solicitaba redibujados periódicos. Ahora se actualiza a 30 Hz; el ambiente del depósito, a 24 Hz. Las pausas detienen los relojes del mundo. La opción de partículas desactiva el humo y la de destellos reducidos estabiliza las balizas. El fondo nuevo de la periferia se combina con la paleta de día, aviso y noche.

## Arte y especificaciones

Se utilizó la **herramienta integrada de generación de imágenes**, siguiendo la familia de acero gris, cobre oxidado, cian y ámbar de las construcciones. Los originales se guardaron en el proyecto:

| Recurso | Uso |
|---|---|
| `assets/expedition/boss/collector_parts_v2.png` | Seis piezas ensamblables del Recaudador |
| `assets/expedition/arena/depot_props_v2.png` | Estación eléctrica, grúa, bomba y carga |
| `assets/background/periphery_alive_v2.png` | Ciudad industrial lateral y canal |

`tools/measure_art.py` mide el alfa y genera recortes; no modifica las imágenes. El atlas del jefe usa celdas explícitas porque las piezas generadas tienen anchuras diferentes. `ArenaLayout` mantiene el contorno físico y visual compartido.

Prompts visuales finales:

- **Piezas del jefe:** atlas transparente de seis piezas separadas, tres columnas y dos filas; perspectiva cenital ortográfica, orientación al sur. Chasis blindado sin orugas adheridas, una oruga independiente, garra hidráulica, escudo frontal curvo, reactor circular y turbina. Píxeles definidos, material metálico detallado, remaches, corrosión, pintura de seguridad gastada, tubos de cobre y luces cian. Sin texto, suelo ni sombras pintadas fuera de las piezas. Las siluetas deben poder ensamblarse y animarse por separado.
- **Decorado del depósito:** atlas transparente de cuatro objetos separados, dos columnas y dos filas, perspectiva cenital: estación eléctrica con bobinas y medidores, grúa de pórtico con cabrestante, bomba de canal con tuberías y turbina, contenedor de carga. Misma familia industrial de acero gris y cobre, franjas ámbar y acentos cian. Sin figuras, letras ni plataformas isométricas.
- **Fondo de periferia:** panorama de pixel art industrial para juego lateral, vista a nivel del suelo. Fábricas de siluetas irregulares, puentes, pasarelas, grúas, depósitos, conductos, cables y pequeñas luces prácticas; canal en la franja inferior. Vía elevada horizontal vacía para superponer tránsito. Cuatro chimeneas claras cerca de 15 %, 37 %, 63 % y 84 % del ancho, sin grandes columnas de humo pintadas; dos extractores visibles. Atmósfera azul grisácea diurna, acero y óxido de cobre, con luces ámbar y cian, adaptable a noche mediante el juego. Sin personas, letras, señales gigantes ni edificios medievales.

## Validación

`tests/depot_life_test.gd`: 98 comprobaciones sobre recogida automática, reservas, plazas compartidas, taller nocturno, aviso contextual, cadencia entre ticks, pausa ambiental, contornos, aparición, colisión, maquinaria y escala de los fragmentos. Las capturas quedan en `.godot/depot/` al usar `-- --capture`.

La batería general incluye **38 suites**, también con simulaciones desde cero en las cinco zonas. Las referencias de arte y procedencia se registran en `ASSET_SOURCES.csv`.

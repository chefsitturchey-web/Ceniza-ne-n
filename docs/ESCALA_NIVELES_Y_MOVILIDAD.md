# Escala, niveles del núcleo y movilidad

## Cambios jugables

El núcleo empieza en **nivel 1** y limita las mejoras de muros y torretas a su propio nivel. Pagar encarga la obra; hasta que llegue y trabaje un constructor no cambia el nivel ni se desbloquea nada. Trabajan hasta dos constructores en el núcleo. Las obras se interrumpen ante peligro cercano y se conservan en el guardado.

| Núcleo | Integridad | Defensas | Profesiones y edificios | Refugio |
|---|---:|---|---|---:|
| 1 | 300 | Muros y torretas de nivel 1 | Constructores, recuperadores, tiradores; cuartel y generador | 8 |
| 2 | 450 | Permite nivel 2 | Guardianes, técnicos, médicos; puesto médico, recicladora y plataforma | Hasta 16 |
| 3 | 650 | Permite nivel 3 | Fortificaciones avanzadas | Hasta 20 |

El paso a nivel 2 cuesta **60** y exige un generador y las cuatro defensas centrales operativas. El paso a nivel 3 cuesta **120**, exige haber resistido una noche y tener dos instalaciones. La obra del núcleo necesita ocho segundos de trabajo de un constructor; dos pueden colaborar. Mejorarlo aumenta la integridad máxima y añade esa diferencia a la salud actual, conservando el daño sufrido. No consume un núcleo de evolución de armas.

Muros y torretas mejoran con E, por 25 y 50 de chatarra, y sus constructores completan la obra. Cada nivel tiene un sprite diferente. Las murallas conservan 240/480/720 de integridad. Las torretas tienen 100/200/300; aumentan daño, alcance y cadencia manteniendo consumo energético. El cabezal sigue apuntando, girando y retrocediendo, con cañón propio por nivel. **T / B** controla la alimentación; ya no comparte la acción de mejora.

Las herramientas y edificios bloqueados explican el nivel requerido antes de cobrar. La clínica neuronal sigue disponible desde el principio. Los guardados anteriores conservan sus defensas: el nivel mínimo del núcleo se deduce de las fortificaciones, refugios y servicios ya construidos. Los guardados nuevos validan que las defensas no superen al núcleo. Al viajar se vuelve a levantar una colonia de nivel 1; se conservan las mejoras neuronales y los habitantes económicos.

## Medidas y apoyo sobre el suelo

El Portador mide unos **35 píxeles de mundo** visibles. Las unidades humanas nuevas se han ajustado a 34–38; el artillero pesado mide 40. Los muros miden 40/54/68 y el núcleo 72/88/106. Las bases de torreta miden 30/40/50, con cabezales articulados por encima. Una cabina inicial es pequeña; la central de nivel 3 domina visualmente la plaza.

La escala se calcula desde el contenido visible del sprite. `data/art_bounds.json` contiene regiones medidas sobre el canal alfa, separando el componente principal para excluir ruido o píxeles de la celda vecina. `ArtScale` sitúa la base de cada región en el suelo. No se usan los márgenes del lienzo como si fueran parte del edificio. Los soldados dejan de hundir los pies al animarse. También se normalizan cuarteles, generadores, clínicas, recicladoras, refugios, campamentos, brechas y transporte de misión.

El refugio se desplaza a x=140 para dejar espacio al núcleo avanzado. Los marcos sin construir siguen siendo cimientos: no representan edificios flotantes. Los reflejos bajo el canal son deliberados; no son copias enterradas de los edificios.

## Plataforma de carga

La movilidad de Kingdom se adapta a un transporte eléctrico. Se compra con **E**, de día, por **45**, junto al taller de x=-880, tras mejorar el núcleo a nivel 2 y despejar las brechas de esa franja. **V / pulsar stick izquierdo** permite subir o bajar junto al vehículo. E también permite subir cuando no compite con otra interacción. Las interacciones del núcleo, edificios y estación tienen prioridad; V permite montar cuando está aparcada junto a ellos.

La velocidad de viaje aumenta un 45 % sin modificar el valor del Inspector. La batería pierde 4 puntos por segundo al moverse. Al agotarse la plataforma avanza más despacio; desmontar recupera la marcha normal. Detenerse junto al núcleo o al taller recarga 20 puntos por segundo. El pasajero mantiene una postura de viaje; no corre sobre la cubierta.

El vehículo queda donde se aparca o donde cae el Portador. Para volver a montarlo hay que regresar a su posición. Propiedad, batería y aparcamiento se guardan. El tren lo lleva al núcleo del distrito siguiente. En las arenas se combate a pie, con la velocidad original, y el HUD de colonia se oculta.

## PixelLab encontrado

El MCP anterior era **PixelLab**, registrado en la configuración de Claude. No estaba expuesto en la lista de herramientas de esta sesión, pero se verificó la conexión con su servidor configurado y se usaron sus herramientas MCP. La búsqueda de plugins no devolvió una integración equivalente.

Se generaron trece PNG nativos: tres núcleos, tres muros, tres pedestales, tres cabezales y una plataforma. `FORTRESS_ASSET_JOBS.json` registra trabajos, semillas y prompts; `ASSET_SOURCES.csv` incluye atribuciones. El MCP procesa una generación cada vez en esta cuenta; se esperó cada resultado, sin cambiar el plan ni la configuración del usuario.

`tools/pixellab_mcp.py` reutiliza la configuración local al ejecutar solicitudes explícitas. No contiene credenciales ni las copia al proyecto. Los cuerpos de solicitudes y respuestas de trabajo quedaron en `.godot/`, fuera de Git. `tools/measure_art.py` lee alfa y genera metadatos; no modifica ninguna imagen. La generación de assets es una tarea de desarrollo: el juego no necesita conexión a PixelLab.

## Referencias y diferencias

- [Town center](https://kingdomthegame.fandom.com/wiki/Town_center): progresión de la base y relación con servicios y defensa.
- [Wall](https://kingdomthegame.fandom.com/wiki/Wall): niveles, reconstrucción y cambios de fortificación.
- [Mounts](https://kingdomthegame.fandom.com/wiki/Mounts): velocidad, agotamiento y recuperación mediante una pausa apropiada.

Kingdom Two Crowns combina más etapas y tecnologías como piedra y hierro; no se afirma que su sistema sea exactamente «base 1, muro 1». Aquí se adapta esa idea a tres niveles industriales claros, con recursos y personajes propios.

## Pruebas y revisión visual

`tests/fortress_progression_test.gd`: 48 comprobaciones sobre requisitos, pagos, trabajo y recorrido, límites, mejoras efectivas, obras en curso, migración, entrada mantenida, práctica F6 y regiones de arte. `tests/mobility_test.gd`: 22 sobre compra, velocidad, animación, batería, aparcamiento, guardado, viaje y combate a pie. La batería general incluye 35 suites y simulaciones desde cero en las cinco zonas, comprando también la mejora del núcleo.

Las capturas OpenGL de niveles 1–3 y plataforma se guardan en `.godot/fortress/` al ejecutar las suites con `-- --capture`. La suite GDD permite revisar las nuevas escalas de soldados y edificios. Se usan perfiles de prueba separados de la partida del usuario. Siguen pendientes pruebas humanas de equilibrio y de duración de campaña.

Para probar manualmente en pocos segundos, abre **`levels/zones/fortress_playground.tscn` y pulsa F6**. Empieza en núcleo 1, con defensas, generador, cuartel, dos constructores y 800 de chatarra de práctica. Mantén E en el núcleo y luego en muros y torretas; T controla energía. Dispone de quince minutos de día y no escribe en tu campaña. El laboratorio de expansión anterior arranca ahora con tecnología 3 para seguir permitiendo probar todos sus edificios.

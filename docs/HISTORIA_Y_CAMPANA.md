# Historia y campaña actual

Actualización posterior: [escala, niveles del núcleo y movilidad](ESCALA_NIVELES_Y_MOVILIDAD.md). Los servicios de apoyo exigen núcleo 2; sus obras y desbloqueos se guardan. La batería general contiene ahora 37 suites.

## Qué se puede jugar

La ruta conecta cinco capítulos: Periferia oxidada, Fundición, Barrio inundado, Ciudadela corporativa y Núcleo de la red. Hay cinco jefes: Recaudador, Santa Caldera, Coro Sumergido, Prefecto y MADRE CERO. Las entradas totales son 2, 4, 6, 8 y 8 respectivamente: dos repetidores terminales y brechas intermedias. El cierre de entradas permite ampliar las defensas y, cuando se cumplen las operaciones y la estabilidad, viajar en tren.

El Portador lleva un enlace que las máquinas no reconocen. Mara quiere construir una red que no cobre por existir; Ivo busca despertar a los cautivos; Vera recupera nombres y rutas; Nox transporta pruebas y suministros. ECO descubre su participación en una orden de emergencia que la red nunca dio por terminada. El objetivo final es revocar esa orden y devolver el control a los asentamientos. Cada capítulo tiene apertura, tres conversaciones desbloqueables y desenlace. El final cierra el arco de los cinco personajes.

L / RB abre el diario y pausa el mundo. Se pueden consultar capítulos anteriores sin revelar los futuros. El objetivo del HUD responde a infraestructura, tropas y operaciones reales. La apertura da una introducción breve; el texto completo queda en el diario.

## Operaciones de cada capítulo

1. **Rescate occidental**, x=-760. Acércate y mantén E. Da una conversación, datos y 15 de chatarra una sola vez. Si una brecha impide llegar, envía antes a la escuadra.
2. **Recuperación del relé oriental**, x=1080. Requiere energía y 30 de chatarra. Un técnico contratado con herramienta en el taller camina hasta el relé y trabaja seis segundos. No se completa solo ni al pagar.
3. **Transporte occidental**, x=-1240. Se activa con E después de las dos operaciones anteriores. Salen dos enemigos de emboscada sin botín. F retira la orden de asalto: los soldados del frente izquierdo pasan a escoltar el vehículo. Solo avanza cuando el Portador está cerca y una tropa armada se encuentra a menos de 260 unidades. El Portador debe acompañarlo hasta el núcleo. Tiene 180 de integridad; si se avería, repararlo cuesta 25. No reinicia las recompensas ni la emboscada. Al llegar entrega 40 de chatarra y datos.

Los fragmentos narrativos son distintos en cada distrito; las tres reglas de operación son compartidas para que se aprendan una sola vez. Las operaciones se guardan, junto con el progreso del técnico y la posición y salud del transporte. Los guardados anteriores que no contienen historia empiezan con las operaciones pendientes.

No hay una victoria automática al tercer amanecer. Los días continúan, los campamentos vuelven a recibir gente y la composición y vida enemigas se limitan a su tercera etapa, evitando un crecimiento irrecuperable por tardar en aprender.

## Los encuentros finales

**El Prefecto** rodea al Portador, protege el frente con su escudo y alterna salvas con estocadas anunciadas. Después de una estocada hace un barrido: sal del círculo. Su recuperación permite daño doble. La segunda fase encadena dos estocadas. La arena usa paredes biseladas, coberturas y señalización dorada.

**MADRE CERO** tiene tres relés aliados. Sostener al menos dos acumula 18 segundos de enlace y abre una ventana de siete segundos para atacar con daño doble. E cerca de un relé recupera 45 de integridad a cambio de 25 de resistencia, incluso si estaba apagado. Q consume 35, protege los relés cuatro segundos y tiene doce de enfriamiento. Los pulsos anuncian dónde impactarán; en segunda fase también marcan al jugador. Las tropas que llevabas en la colonia reducen el daño a relés; con cuatro soldados el enlace carga algo más rápido. La arena final es una plataforma de doce lados.

El Coro también recibe un sprite original detallado, con antenas, corrosión, cables, apertura luminosa y goteo. Se conservan sus tres enlaces y su mecánica anterior. Los dos jefes nuevos tienen sprites propios y movimiento; las señales y colisiones se resuelven por separado del dibujo.

## Duración: estado real y objetivo

**Cuatro horas todavía no están demostradas ni garantizadas.** El GDD original propone incluso 10–14 horas para una primera campaña; esa cifra también era una meta. Este bloque añade dos zonas, dos jefes, quince operaciones, historia y un final, pero no convierte por sí solo el prototipo en una campaña de cuatro horas de contenido variado.

Se conservan los tiempos del proyecto: 180 segundos de día, 20 de aviso y 90 de noche. Las simulaciones de asedio de tres noches duran 870,5 segundos en cada zona; omiten exploración narrativa y no miden una primera partida humana. Alargar esos temporizadores para afirmar una duración sería una validación insuficiente.

Para alcanzar la duración solicitada falta medir partidas completas y ampliar los momentos que resulten cortos: operaciones exclusivas por distrito, nuevas composiciones de asedio, elecciones con consecuencias y expediciones opcionales con recompensas únicas. No se publica una estimación de cuatro horas como si ya estuviera verificada. Las entradas siguen siendo puntos prefijados, no mapas por semilla; el remapeo completo, los perfiles iniciales y todo el catálogo de armas del GDD continúan pendientes.

## Cómo probar

- F5: jugar desde el menú y seguir el objetivo / L para el diario.
- F6 en `levels/zones/citadel.tscn` o `network.tscn`: abrir las colonias finales.
- F6 en `levels/expedition/prefect_arena.tscn` o `mother_arena.tscn`: practicar los jefes directamente.
- `tests/commander_test.gd`: política de combate y asalto completo sin ataques personales.
- `tests/story_finale_test.gd`: operaciones físicas, escolta con combate, diario, JSON, guardado, cuarto día y reglas de ambos jefes.
- `tests/campaign_bosses_test.gd`: viajes reales por las cinco escenas y restauración de avances.
- `tests/run_all.gd`: 30 suites, incluidas cinco simulaciones desde cero con costes reales.

Con `-- --capture`, las suites de historia y campaña guardan imágenes en `.godot/story/` y `.godot/campaign/`; se excluyen de Git. Las pruebas usan un APPDATA aislado para proteger la partida del usuario.

## Especificaciones de los recursos originales

Paleta base: carbón y acero `#0B1322`, `#182639`, `#304356`, `#8299A8`; cobre `#704C43`, `#E89E54`; luz cálida `#FFCE75`, energía `#47DACB`, amenaza `#DD6482`. Sin texto incrustado, con siluetas completas y márgenes.

- `field_atlas_v3.png`: atlas transparente 4×2, lateral hacia la derecha, escala de personaje de 48 píxeles lógicos. Tirador con fusil y abrigo, guardián con escudo, técnico de amarillo y médico blanco; civil, dron médico, artillero y saboteador en la fila inferior. Desgaste, telas, mochilas y equipo distinguibles.
- `civic_atlas_v3.png`: atlas transparente 2×2, elevación lateral: campamento con farol y fogón, refugio con literas, taller abierto con herramientas y brecha industrial con arco y energía violeta.
- `skills_atlas_v1.png`: dieciséis iconos en cuadrícula 4×4, legibles a 32–44 píxeles: hoja, dron, Tesla, orbital; óptica, batería, rodamiento, imán; condensador, recuperación, escudo, herramienta; botiquín, núcleo, chatarra, señal.
- `final_bosses_v1.png`: atlas transparente 2×1 cenital: duelista corporativo con escudo y sable; reina mecánica de servidores, corazón neuronal y cables. `choir_v2.png`: aparato de radio flotante con corona de antenas, corrosión y núcleo luminoso.
- `citadel.png` y `network.png`: panoramas laterales, Ciudadela de edificios corporativos y sala de servidores bajo tierra, profundidad atmosférica, suelo de lectura limpia y sin personajes ni interfaz.

Recursos producidos mediante la habilidad imagegen; sus originales se conservan y las copias usadas viven dentro del proyecto. Atribución en `ASSET_SOURCES.csv`. Referencias de Kingdom y las adaptaciones mecánicas en [Comandante y portales](COMANDANTE_Y_PORTALES.md).

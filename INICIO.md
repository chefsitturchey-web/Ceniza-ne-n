# CENIZA NEÓN: cómo jugar

Abre `project.godot` en Godot 4 y pulsa **F5**. Nueva partida inicia la campaña; Continuar recupera tu colonia y operaciones. Hay guardado al amanecer y al completar operaciones. Perder el núcleo permite recuperar el último guardado. La campaña tiene cinco capítulos y un final; **la meta de cuatro horas aún necesita más contenido y pruebas de duración**.

La historia se presenta con retratos manga a color, conversaciones y fundidos. **E / Enter / Espacio** avanza; **Esc** omite. En **L → Ver conversación** puedes releer escenas. Para probar todo el guion con F6, abre `levels/story/novel_preview.tscn`. [Detalles y dirección visual](docs/NOVELA_VISUAL_Y_COHERENCIA.md).

## Controles

Para revisar las animaciones de aliados y profesiones, abre `levels/story/unit_animation_preview.tscn` y pulsa **F6**. [Guía de personajes y archivos de LibreSprite](docs/PERSONAJES_Y_ANIMACIONES.md).

| Acción | Teclado | Mando Xbox |
|---|---|---|
| Mover | A/D o flechas | Stick izquierdo / cruceta |
| Construir, reclutar, comprar herramientas, operar | Mantener E | Mantener Y |
| Asaltar el frente donde estás / retirar tropas | F | Cruceta arriba |
| Esquivar | Espacio | A |
| Sobrecargar el frente | Q | LB |
| Alimentación de una torreta cercana | T | B |
| Subir o bajar de la plataforma cercana | V | Pulsar stick izquierdo |
| Diario y objetivo | L | RB |
| Pausar | Esc | Start |
| Atacar, solo en arenas de jefe | J | X |

En la colonia **tus tropas y torretas combaten**. El Portador organiza, explora, recoge datos, esquiva y activa sobrecargas. Sus armas personales funcionan contra los jefes; los módulos equipados también transmiten una bonificación de daño a los soldados.

En arenas te mueves también con **W/S**. Los jefes reaccionan a tu posición y trayectoria; observa los avisos y sus ventanas de recuperación. **E** cerca de las consolas cian activa carga, refrigeración, interferencia o parapeto, según el recinto. En Madre Cero, E repara relés y Q los protege. Los refuerzos pueden recibir daño de tu hoja y módulos. [Los cinco jefes, mecanismos y escenas para probar con F6](docs/JEFES_TACTICAS_Y_ARENAS.md).

## Primeros pasos

1. Empiezas con 90 de chatarra, un constructor y un recuperador. Mantén E en los cuatro cimientos centrales: dos murallas de 20 y dos torretas de 25. El constructor debe caminar y ejecutar las obras.
2. Explora los suministros y construye un generador a izquierda o derecha, a 360 del núcleo. Añade cuarteles para alojar tropas. El generador amplía la capacidad energética; no produce una moneda consumible.
3. El núcleo comienza en nivel 1 y tus defensas también. Tras terminar el generador y las cuatro defensas, mantén E en el núcleo: por 60 encargas el nivel 2. El constructor debe terminarlo. Se desbloquean mejoras de defensas, guardianes, técnicos, médicos y transporte. El nivel 3 cuesta 120 y exige una noche resistida y dos instalaciones. Cada nivel cambia de diseño.
4. Recluta personas en los campamentos con E y compra herramientas en el taller izquierdo. Una persona sin profesión recoge una herramienta disponible. Conviene formar un guardián y dos tiradores por cuartel antes de asaltar. El refugio se amplía según el nivel del núcleo.
5. Durante la noche mantén las defensas y usa Q en el frente bajo presión. Los trabajadores se retiran ante el peligro. Para ampliar el perímetro paga murallas exteriores y espera a los constructores.
6. F ordena a los soldados del frente atacar la entrada más cercana. Los portales avisan y generan defensores al perder vida. Otra F retira la escuadra. Esos refuerzos no dan botín: no se puede ganar experiencia infinita provocando una puerta.
7. Recoge los datos que dejan los enemigos. Cada nivel pausa el juego y ofrece armas, pasivas o implantes con iconos. Hay dos ranuras de módulo y cuatro pasivas; evoluciona con nivel 5, catalizador y núcleo. La clínica permite consultar y equipar lo que ya obtuviste.

Si una persona no recoge una herramienta, consulta el aviso sobre el taller: indica la instalación o plaza que falta. Las herramientas reservadas no se pierden. De noche pueden recogerlas si el taller queda dentro de las murallas y está a salvo. [Recogida, animaciones y nuevo depósito del jefe](docs/DEPOSITO_Y_VIDA_DEL_DISTRITO.md).

## Historia, operaciones y tren

**L abre el diario.** La ruta es Periferia → Fundición → Barrio inundado → Ciudadela → Núcleo de la red. Mara, Ivo, Vera, Nox y ECO revelan por qué las máquinas siguen ejecutando una emergencia que nunca terminó.

Cada capítulo exige rescatar la baliza occidental (-760), recuperar el relé oriental (+1080) y escoltar el transporte (-1240) hasta el núcleo. El relé necesita energía, 30 de chatarra y un técnico que llegue y trabaje. El transporte requiere al Portador cerca y soldados que lo protejan. Tras activarlo, F retira la orden de asalto para que las tropas izquierdas pasen a escoltarlo. Una avería se repara con E por 25.

Cierra las entradas con tus tropas, completa las tres operaciones y estabiliza la colonia: dos murallas centrales, generación y al menos una noche resistida. Después toma el tren de día con E. Los días siguen avanzando después del tercero y reponen reclutas. El daño y vida de los enemigos no crecen indefinidamente por tardar.

## Jefes

- **Recaudador:** haz que embista una cobertura y golpea su núcleo expuesto.
- **Santa Caldera:** evita franjas calientes, salvas y arremetidas; ataca durante la purga.
- **Coro Sumergido:** corta sus tres enlaces y aprovecha la apertura.
- **Prefecto:** rodea su escudo, esquiva la estocada y sal del barrido. En segunda fase encadena estocadas.
- **MADRE CERO:** mantén al menos dos relés activos. E cerca de uno repara a cambio de resistencia; Q protege de los pulsos. El enlace abre la ventana para atacar. Tus soldados de la colonia aportan apoyo a los relés.

Las arenas permiten movimiento en ocho direcciones y combate personal. Si pierdes vuelves a la colonia; si ganas continúas con tus mejoras y habitantes económicos. La última victoria cierra la historia.

## Transporte opcional

Con núcleo de nivel 2 puedes comprar una plataforma eléctrica por 45 junto al taller de x=-880. E compra o monta; V sube y baja cerca de ella. Aumenta la velocidad de viaje un 45 %. Detente en el núcleo o en ese taller para recargar la batería. Queda aparcada al bajar y viaja contigo en tren. Contra los jefes vas a pie. [Niveles, medidas, desbloqueos y pruebas](docs/ESCALA_NIVELES_Y_MOVILIDAD.md).

## Pruebas rápidas en Godot

- Niveles, diseños y transporte: **F6 en `levels/zones/fortress_playground.tscn`**. Ofrece presupuesto, generador y defensas de práctica, sin guardar en campaña.
- Colonias finales: F6 en `levels/zones/citadel.tscn` o `network.tscn`.
- Jefes: F6 en `levels/expedition/recaudador_arena.tscn`, `caldera_arena.tscn`, `choir_arena.tscn`, `prefect_arena.tscn` o `mother_arena.tscn`.
- Laboratorio con presupuesto de práctica: `levels/zones/expansion_playground.tscn`. Esa escena no guarda sobre tu partida.
- Batería automática: `godot --headless --path . --script res://tests/run_all.gd` (sustituye `godot` por tu ejecutable de consola).

Se conservan los tiempos de 180 s de día, 20 de aviso y 90 de noche. [Historia, objetivos, arte y estado real de duración](docs/HISTORIA_Y_CAMPANA.md). [Reglas de comandante y estudio de Kingdom Two Crowns](docs/COMANDANTE_Y_PORTALES.md).

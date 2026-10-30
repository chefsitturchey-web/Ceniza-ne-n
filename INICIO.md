# CENIZA NEÓN: cómo jugar

Abre `project.godot` en Godot 4 y pulsa **F5**. Nueva partida inicia la campaña; Continuar recupera tu colonia y operaciones. Hay guardado al amanecer y al completar operaciones. Perder el núcleo permite recuperar el último guardado. La campaña tiene cinco capítulos y un final; **la meta de cuatro horas aún necesita más contenido y pruebas de duración**.

**Para probar libremente: pulsa F1.** El laboratorio permite entrar a los cinco jefes sin requisitos, elegir fase y equipo, activar invulnerabilidad, cámara lenta, crear unidades y preparar colonias. **F2** invulnerabilidad, **F3** congelar enemigos, **F4** colisiones y rutas. Los trucos marcan la sesión como práctica y conservan el checkpoint normal. [Guía del laboratorio](docs/interface/LABORATORIO_DEPURACION.md).

**Nuevo arte ilustrado y animado:** Portador y jefes basados en sus retratos manga, con materiales detallados y poses completas. El Portador conserva unos 35 píxeles de altura de mundo y tiene marcha, estocada, reacción, voltereta y caída para ambas cámaras. Pulsa **F6 en `levels/story/combat_animation_preview.tscn`**; activa **Giro**, pulsa **1–6** para detalle y **0** para volver al conjunto. Alterna cámara para compararlo con el guardián. [Fuentes de LibreSprite, prompts y diseño](docs/art/ARTE_COMBATE_ILUSTRADO.md).

La historia se presenta con retratos manga a color, conversaciones y fundidos. **E / Enter / Espacio** avanza; **Esc** omite. En **L → Ver conversación** puedes releer escenas. Para probar todo el guion con F6, abre `levels/story/novel_preview.tscn`. [Detalles y dirección visual](docs/art/NOVELA_VISUAL_Y_COHERENCIA.md).

## Controles

Para revisar las animaciones de aliados y profesiones, abre `levels/story/unit_animation_preview.tscn` y pulsa **F6**. [Guía de personajes y archivos de LibreSprite](docs/art/PERSONAJES_Y_ANIMACIONES.md).

| Acción | Teclado | Mando Xbox |
|---|---|---|
| Mover | A/D o flechas | Stick izquierdo / cruceta |
| Correr (gasta estamina) | Mantener Shift | Cruceta abajo |
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

En arenas te mueves también con **W/S**. Los jefes reaccionan a tu posición y trayectoria; observa los avisos y sus ventanas de recuperación. **E** cerca de las consolas cian activa carga, refrigeración, interferencia o parapeto, según el recinto. En Madre Cero, E repara relés y Q los protege. Los refuerzos pueden recibir daño de tu hoja y módulos. [Los cinco jefes, mecanismos y escenas para probar con F6](docs/gameplay/JEFES_TACTICAS_Y_ARENAS.md).

## Primeros pasos

**El mapa tiene poblados recuperables.** Consulta **L → Poblados** para encontrar componentes especiales y restaurar talleres, armerías o dispensarios. Necesitan materiales y constructores; mejoran obras, daño aliado o curación local. [Ubicaciones, costes y bonificaciones](docs/gameplay/POBLADOS_Y_TECNOLOGIA.md).

1. Empiezas con un constructor y un recolector, sin núcleo. Las dos baterías junto al punto de llegada contienen las primeras piezas. Mantén E para extraerlas.
2. Con 12 piezas y 20 de chatarra, mantén E en el cimiento central. El constructor levanta el núcleo en 24 segundos. Hasta encenderlo, el asedio y la recolección automática esperan.
3. Construye las dos murallas centrales. Encarga con E el despeje de una parcela de generador; cuesta 5 de chatarra y requiere que llegue un constructor. Después paga su construcción.
4. Murallas, generador, 60 de chatarra y 10 piezas permiten encargar el núcleo Nv.2. Entonces se desbloquean las torretas. Las defensas tardan 16 segundos y las instalaciones 24, además del viaje del trabajador.
5. La mochila lleva 24 piezas. El exceso cae y cada pieza tiene un 25 % de probabilidad de romperse. E recoge los montones si queda espacio. Regresa al núcleo para descargar automáticamente al depósito.
6. Recluta en los campamentos y compra herramientas en el taller izquierdo. Un cuartel permite formar tropas; F ordena atacar el portal de ese frente y otra F las retira. Cierra los portales para abrir las parcelas exteriores.
7. El núcleo Nv.3 exige una noche resistida, dos instalaciones, 120 de chatarra y 18 piezas. Amplía la capacidad de energía y las mejoras de defensas. L muestra el objetivo y permite releer la historia.

Cada distrito mide 14.400 píxeles y tiene su propio trazado de solares y obstáculos. Shift permite correr; el transporte se desbloquea con núcleo Nv.2. [Reglas completas, diseños de LibreSprite y guardados](docs/gameplay/FRONTERA_Y_RECONSTRUCCION.md).

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

Con núcleo de nivel 2 puedes comprar una plataforma eléctrica por 45 junto al taller de x=-880. E compra o monta; V sube y baja cerca de ella. Aumenta la velocidad de viaje un 45 %. Detente en el núcleo o en ese taller para recargar la batería. Queda aparcada al bajar y viaja contigo en tren. Contra los jefes vas a pie. [Niveles, medidas, desbloqueos y pruebas](docs/gameplay/ESCALA_NIVELES_Y_MOVILIDAD.md).

## Pruebas rápidas en Godot

- Niveles, diseños y transporte: **F6 en `levels/zones/fortress_playground.tscn`**. Ofrece presupuesto, generador y defensas de práctica, sin guardar en campaña.
- Colonias finales: F6 en `levels/zones/citadel.tscn` o `network.tscn`.
- Jefes: F6 en `levels/expedition/recaudador_arena.tscn`, `caldera_arena.tscn`, `choir_arena.tscn`, `prefect_arena.tscn` o `mother_arena.tscn`.
- Laboratorio con presupuesto de práctica: `levels/zones/expansion_playground.tscn`. Esa escena no guarda sobre tu partida.
- Batería automática: `godot --headless --path . --script res://tests/run_all.gd` (sustituye `godot` por tu ejecutable de consola).

Se conservan los tiempos de 180 s de día, 20 de aviso y 90 de noche. [Historia, objetivos, arte y estado real de duración](docs/design/HISTORIA_Y_CAMPANA.md). [Reglas de comandante y estudio de Kingdom Two Crowns](docs/gameplay/COMANDANTE_Y_PORTALES.md).

# CENIZA NEÓN: cómo jugar

Abre `project.godot` en Godot 4 y pulsa **F5**. Nueva partida inicia la campaña; Continuar recupera tu colonia y operaciones. Hay guardado al amanecer y al completar operaciones. Perder el núcleo permite recuperar el último guardado. La campaña tiene cinco capítulos y un final; **la meta de cuatro horas aún necesita más contenido y pruebas de duración**.

## Controles

| Acción | Teclado | Mando Xbox |
|---|---|---|
| Mover | A/D o flechas | Stick izquierdo / cruceta |
| Construir, reclutar, comprar herramientas, operar | Mantener E | Mantener Y |
| Asaltar el frente donde estás / retirar tropas | F | Cruceta arriba |
| Esquivar | Espacio | A |
| Sobrecargar el frente | Q | LB |
| Diario y objetivo | L | RB |
| Pausar | Esc | Start |
| Atacar, solo en arenas de jefe | J | X |

En la colonia **tus tropas y torretas combaten**. El Portador organiza, explora, recoge datos, esquiva y activa sobrecargas. Sus armas personales funcionan contra los jefes; los módulos equipados también transmiten una bonificación de daño a los soldados.

## Primeros pasos

1. Empiezas con 90 de chatarra, un constructor y un recuperador. Mantén E en los cuatro cimientos centrales: dos murallas de 20 y dos torretas de 25. El constructor debe caminar y ejecutar las obras.
2. Explora los suministros y construye un generador a izquierda o derecha, a 360 del núcleo. Añade cuarteles para alojar tropas. El generador amplía la capacidad energética; no produce una moneda consumible.
3. Recluta personas en los campamentos de ambos extremos con E. Compra herramientas en el taller izquierdo: martillo, equipo recuperador, fusil, escudo, herramienta técnica o botiquín. Una persona sin profesión recoge una herramienta disponible. Conviene formar un guardián y dos tiradores por cuartel antes de asaltar.
4. Durante la noche mantén las defensas y usa Q en el frente bajo presión. Los trabajadores se retiran ante el peligro. Para ampliar el perímetro paga murallas exteriores y espera a los constructores.
5. F ordena a los soldados del frente atacar la entrada más cercana. Los portales avisan y generan defensores al perder vida. Otra F retira la escuadra. Esos refuerzos no dan botín: no se puede ganar experiencia infinita provocando una puerta.
6. Recoge los datos que dejan los enemigos. Cada nivel pausa el juego y ofrece armas, pasivas o implantes con iconos. Hay dos ranuras de módulo y cuatro pasivas; evoluciona con nivel 5, catalizador y núcleo. La clínica permite consultar y equipar lo que ya obtuviste.

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

## Pruebas rápidas en Godot

- Colonias finales: F6 en `levels/zones/citadel.tscn` o `network.tscn`.
- Jefes: F6 en `levels/expedition/recaudador_arena.tscn`, `caldera_arena.tscn`, `choir_arena.tscn`, `prefect_arena.tscn` o `mother_arena.tscn`.
- Laboratorio con presupuesto de práctica: `levels/zones/expansion_playground.tscn`. Esa escena no guarda sobre tu partida.
- Batería automática: `godot --headless --path . --script res://tests/run_all.gd` (sustituye `godot` por tu ejecutable de consola).

Se conservan los tiempos de 180 s de día, 20 de aviso y 90 de noche. [Historia, objetivos, arte y estado real de duración](docs/HISTORIA_Y_CAMPANA.md). [Reglas de comandante y estudio de Kingdom Two Crowns](docs/COMANDANTE_Y_PORTALES.md).
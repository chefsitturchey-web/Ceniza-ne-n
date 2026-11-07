# Niveles, escala y movilidad

## Núcleo y desbloqueos

`ColonyCore.tier` empieza en **0**. Encenderlo cuesta 20 de chatarra y 12 piezas. Cada encargo necesita 24 segundos de trabajo de constructor; pagar no lo completa.

| Nivel completado | Integridad máxima | Reglas |
| --- | --- | --- |
| 1 | 300 | Murallas, generador, cuartel y profesiones básicas; torretas bloqueadas |
| 2 | 450 | Torretas, defensas Nv.2, guardianes, técnicos, médicos y transporte |
| 3 | 650 | Defensas Nv.3 y mejoras avanzadas |

Nv.2 requiere generador, ambas murallas centrales, 60 de chatarra y 10 piezas. Nv.3 requiere también una noche resistida y dos instalaciones, con 120 de chatarra y 18 piezas. La mejora aumenta la salud máxima y cura su diferencia, conservando daño previo. Guardado y migración deducen el nivel compatible de las fortificaciones antiguas.

`FortressRules` limita profesiones e instalaciones y calcula daño, alcance y cadencia por nivel de defensa. **E** encarga obras o mejoras; **T** controla la alimentación de la torreta cercana. Las obras nocturnas siguen las [reglas de riesgo](TRABAJO_NOCTURNO.md).

Fuentes: `entities/structures/colony_core.gd`, `systems/fortress_rules.gd`, `systems/construction_system.gd` y `systems/civic_system.gd`.

## Escala visual

`components/art_scale.gd` usa límites del contenido visible registrados en `data/art_bounds.gd` y `.json`. Las celdas transparentes no equivalen al tamaño del personaje o edificio. El combate utiliza las escalas y anclajes de `assets/characters/combat/layout.json`; las unidades tienen su biblioteca y ajuste propios. Revisar el apoyo sobre el suelo en las galerías y el mundo real.

## Plataforma de carga

`systems/mobility_system.gd` ofrece transporte en x=-880 por **45 de chatarra**, de día y con núcleo Nv.2, en una franja liberada. E compra/monta y **V** sube o baja cerca de la plataforma. Al desmontar queda aparcada.

Con batería, multiplica la velocidad de viaje por **1,45**. Moverse consume 4 puntos por segundo; detenerse en núcleo o taller recarga 20 por segundo. Sin batería usa factor 0,85; desmontar restaura la marcha. Propiedad, carga y posición se guardan. El traspaso de campaña la deja desmontada junto al núcleo siguiente. No se usa en arenas.

## Probar

F5 → Nueva partida para comprobar fundación y requisitos. F6 en `levels/zones/fortress_playground.tscn` permite revisar diseños; F1 prepara práctica. Validar con `tools/maintenance/validate.ps1`: `frontier_progression_test`, `fortress_progression_test` y `mobility_test` están entre las 67 ejecuciones de `tests/run_all.gd`.

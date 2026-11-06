# CENIZA NEÓN: cómo jugar

Importa `project.godot` en Godot 4.7.2 y pulsa **F5**. **Nueva partida** inicia una campaña y reinicia su guía; **Continuar** carga el checkpoint. **Boss Rush** abre los cinco jefes seguidos sin historia y conserva sus marcas en un archivo separado.

## Colonia y primeros pasos

La novela de llegada se reproduce automáticamente, también con la guía activa. **E / Intro / Espacio / clic** avanza y **Esc** omite. Después sigue la flecha y mantén la acción indicada: sus avisos respetan el teclado, mando, táctil y reasignaciones.

1. Empiezas con un constructor, un recuperador y 90 de chatarra, sin núcleo construido. Extrae piezas de las baterías cercanas manteniendo **E**.
2. Encarga el núcleo central por **12 piezas y 20 de chatarra**. Necesita 24 segundos de trabajo; el asedio espera a que se encienda.
3. Levanta las dos murallas, despeja una parcela de generador y construye el generador.
4. El núcleo Nv.2 cuesta **60 de chatarra y 10 piezas** y requiere ambas murallas y generación. Desbloquea torretas, apoyo y transporte.
5. Descarga las piezas al acercarte al núcleo: la mochila admite 24. El exceso cae y puede romperse. El depósito queda en ese distrito.
6. Recluta en campamentos y compra herramientas en el Arsenal izquierdo. Los habitantes recogen las herramientas cuando hay plaza para su profesión. **F** ordena asaltar tu frente; otra pulsación retira las tropas.

Las tropas y torretas combaten en la colonia. El Portador dirige, recoge recursos, esquiva y activa la sobrecarga. Aceptar una obra o reparación de noche autoriza el trabajo nocturno: aparece «De noche: tu gente puede morir». Los trabajadores salen al 80 % de ritmo y quedan expuestos hasta el amanecer.

[Guía y rondas](docs/gameplay/PRIMEROS_PASOS_Y_RONDAS.md) · [Frontera](docs/gameplay/FRONTERA_Y_RECONSTRUCCION.md) · [Trabajo nocturno](docs/gameplay/TRABAJO_NOCTURNO.md).

## Controles

| Acción | Teclado | Mando Xbox |
| --- | --- | --- |
| Mover | A/D o flechas; W/S en arena | Stick / cruceta |
| Correr | Mantener Shift | Cruceta abajo |
| Construir / operar | Mantener E | Mantener Y |
| Asaltar / retirar | F | Cruceta arriba |
| Esquivar | Espacio | A |
| Sobrecargar | Q | LB |
| Alimentar torreta | T | B |
| Subir / bajar de plataforma | V | Pulsar stick izquierdo |
| Diario | L | RB |
| Pausa | Esc | Start |
| Atacar en arena | J | X |

La pausa de colonia muestra controles; las pausas de colonia y jefe ofrecen Opciones. **Opciones → Controles** permite cambiar tecla y botón; **Avisos de teclas** fija Automático, Teclado o Mando. `TextMarks` resalta las entradas en dorado. En pantallas táctiles aparecen joystick y botones durante el juego. **M** silencia el audio.

## Historia y jefes

La ruta es Periferia → Fundición → Barrio inundado → Ciudadela → Núcleo de la red. En cada distrito completa rescate, relé y convoy, cierra las entradas y estabiliza la colonia; toma el tren de día. **L** muestra el objetivo, las conversaciones desbloqueadas y la pestaña Poblados con instalaciones y tecnología recuperable. Las posiciones varían por la semilla guardada de campaña.

En los jefes combate con **J**, esquiva con **Espacio** y utiliza **E** en los mecanismos. Las pistas cortas explican controles y oportunidades. Los ataques cuerpo a cuerpo anuncian arcos, círculos o líneas antes del daño. Busca las ventanas de núcleo expuesto.

- Recaudador: rodea el escudo y aprovecha sus choques contra cobertura.
- Santa Caldera: evita el calor y aprovecha la purga.
- Coro Sumergido: rompe las tres antenas.
- Prefecto: evita el escudo y castiga la recuperación; al 30 % entra en última guardia.
- Madre Cero: mantén dos relés activos; E repara y Q protege. Al 30 % activa el último protocolo.

En historia, la entrada se lee antes de la presentación de combate y el desenlace tras la muerte, antes de resolver la expedición. El diario permite releer lo desbloqueado. Boss Rush omite ambas novelas: sus resultados muestran tiempo, golpes y top 5; las diez mejores victorias se guardan con nombre.

[Historia completa](docs/gameplay/HISTORIA_FLUJO.md) · [Tácticas](docs/gameplay/JEFES_TACTICAS_Y_ARENAS.md) · [Boss Rush](docs/gameplay/BOSS_RUSH.md).

## Probar funciones

- **F1** abre el laboratorio en editor/depuración: práctica de cinco jefes, fases y equipo. F2 activa invulnerabilidad, F3 congela IA y F4 muestra geometría. Los trucos de colonia desactivan su guardado de campaña.
- **F6** ejecuta la escena abierta: `levels/story/novel_preview.tscn`, `unit_animation_preview.tscn` o `combat_animation_preview.tscn` son galerías.
- Observa los fondos al caminar, pausa y cambia Partículas o Reducir destellos. El audio se ajusta por Master, Music y SFX.
- Para validar, usa `tools/maintenance/validate.ps1` con `-GodotPath` al ejecutable de consola. `tests/run_all.gd` contiene 67 ejecuciones; resultados en `build/validation/latest/`.

Fuentes: `ui/main_menu.gd`, `core/key_remap.gd`, `core/input_glyphs.gd`, `systems/first_steps.gd`, `entities/structures/colony_core.gd`, `systems/colony_system.gd`, `data/frontier_layout.gd` y `levels/expedition/recaudador_arena.gd`.

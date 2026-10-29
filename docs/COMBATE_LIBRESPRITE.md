# Portador y cinco jefes en LibreSprite

## Qué se cambió

Los seis actores de combate usan **fotogramas completos dibujados y exportados desde LibreSprite**. Cada actor tiene **256 fotogramas**, distribuidos en diez secuencias y cuatro direcciones: sur, este, norte y oeste. En total hay **1536 fotogramas**. El Portador también utiliza su sprite nuevo en la colonia.

El dibujo es procedural original: `tools/libresprite_combat.js` traza píxeles, polígonos, luces, costuras, remaches, rejillas, herrajes y articulaciones mediante la API JavaScript nativa de LibreSprite. En este conjunto no hay imágenes generadas por IA como entrada. Se dibujan cuerpo, arma, mecanismos y efectos en cada celda; el renderizado ocurre dentro del editor. No se afirma que estos sprites se hayan dibujado manualmente con ratón.

![Galería de los seis personajes](media/combat_libresprite.png)

## Fuentes y dimensiones

Las fuentes están en **`assets/combat/native/sources/`**. Ábrelas con LibreSprite; pulsa reproducir y selecciona las etiquetas de la línea de tiempo.

| Archivo editable | Lienzo por fotograma | Anclaje en píxeles |
| --- | --- | --- |
| `portador.ase` | 96 × 96 | 48, 72: apoyo de los pies |
| `recaudador.ase` | 128 × 128 | 64, 64 |
| `caldera.ase` | 128 × 128 | 64, 64 |
| `coro.ase` | 128 × 128 | 64, 64 |
| `prefecto.ase` | 160 × 160 | 80, 96 |
| `madre.ase` | 128 × 128 | 64, 64 |

El tamaño del lienzo incluye espacio transparente para espadas, brazos y efectos; no indica la altura física del personaje. El cuerpo del Portador mide aproximadamente 40 píxeles. El Prefecto tiene un lienzo mayor para que su espada y escudo no se recorten; se dibuja a escala 1:1 en el combate. La galería amplía al Portador al doble para observarlo.

Cada documento contiene tres capas editables: **Cuerpo y apoyo**, **Armas y mecanismos** y **Efectos dibujados**. Las etiquetas son `idle`, `walk`, `windup`, `attack`, `shoot`, `charge`, `exposed`, `hurt`, `death`, `dodge`, con sufijos de dirección. Son 40 etiquetas por actor; algunas son de previsualización y no corresponden a una habilidad disponible en la IA de todos los jefes.

## Probar

1. Abre **`levels/story/combat_animation_preview.tscn`** y pulsa **F6**. Cambia secuencia y dirección para ver los seis actores.
2. Con el juego abierto, pulsa **F1 → Jefes → Entrar**. Puedes comparar fase, vulnerabilidad, ataque y muerte con el laboratorio.
3. Muévete con WASD y ataca con J. La espada cambia de pose junto al brazo y el torso. El antiguo arco y rayo dibujado de ataque queda desactivado con los sprites nuevos.

La caminata avanza por distancia recorrida: los redibujados sin movimiento no inventan pasos. La zancada del Portador es de 80 unidades de mundo por ciclo, para que los pies no cambien de fotograma a la velocidad de renderizado. Preparación y golpe se sincronizan con el tiempo de ataque; el daño se emite una sola vez después del primer cuarto de la animación. Esquivar cancela un golpe en preparación y un impacto interrumpe la acción.

Los jefes conservan sus reglas de combate. Sus imágenes anteriores permanecen como alternativa: en el Inspector, desactiva **Native Combat Art** del actor para recuperar la representación anterior. La representación nueva se ocupa de las poses y la anterior se mantiene oculta. El núcleo expuesto, las salvas y los avisos siguen ligados al estado real del jefe. Las muertes tienen secuencia propia y fragmentos pequeños; no se obtiene la caída girando una ilustración entera.

Este bloque cambia arte y presentación del combate; las arenas y la progresión táctica se documentan en [Jefes, tácticas y arenas](JEFES_TACTICAS_Y_ARENAS.md). La dificultad y el acabado artístico siguen necesitando valoración en partidas reales.

## Editar y exportar

Detén el juego antes de cambiar los archivos. Edita las celdas o capas en LibreSprite y conserva el orden, dimensiones y etiquetas de la línea de tiempo. Exporta la hoja en filas, con ocho columnas, sobre el PNG del mismo nombre en `assets/combat/native/`. Si cambias la cantidad u orden de fotogramas, actualiza también `layout.json`.

Ejemplo de exportación de una fuente ya editada:

```powershell
& 'D:/descargas/libresprite-development-windows-x86_64/libresprite.exe' --batch assets/combat/native/sources/portador.ase --sheet-type rows --sheet-width 768 --sheet assets/combat/native/portador.png
```

Para regenerar desde el código de dibujo original:

```powershell
python tools/build_combat_sprites.py
python tools/build_combat_sprites.py --actors portador prefecto
```

Python solo prepara documentos ASE vacíos, etiquetas y metadatos. **LibreSprite** dibuja los píxeles y exporta las hojas. El constructor exige una marca de finalización por actor para detectar errores del motor de scripts aunque el ejecutable termine con código 0. Las huellas de las fuentes están en `provenance.json`: si detecta cambios manuales posteriores, se detiene para conservarlos. `--overwrite-edits` permite una regeneración explícita que reemplaza esos cambios; exportar tu ASE editado no requiere ese argumento.

Se verificó una reconstrucción nativa con PNG idénticos byte a byte. Cachés, documentos vacíos y registros de trabajo permanecen en `.godot/combat-art/`; no se incluyen en Git.

## Validación y referencias

`tests/native_combat_art_test.gd`: **1851 comprobaciones**, incluyendo márgenes sin recortes, poses distintas, fuentes editables, caché de fotogramas, galería F6, pasos por distancia, anticipación sin daño temprano, dirección del golpe, cancelación por esquiva, impacto y muerte. La batería general incluye **38 suites**.

Se consultaron la [API oficial de scripts de LibreSprite](https://github.com/LibreSprite/LibreSprite/blob/master/SCRIPTING.md), sus [opciones oficiales de exportación](https://github.com/LibreSprite/LibreSprite/blob/master/src/app/app_options.cpp) y la [aclaración de sus mantenedores sobre JavaScript y las diferencias con Aseprite](https://github.com/LibreSprite/LibreSprite/issues/360). Los scripts de Aseprite no se asumieron compatibles.

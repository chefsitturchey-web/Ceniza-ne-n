# Personajes y animaciones en LibreSprite

## Probar en Godot

Abre `levels/story/unit_animation_preview.tscn` y pulsa **F6**. El selector permite revisar las poses de las nueve variantes, invertir la dirección y pausar. Las secuencias de una sola reproducción se repiten cada dos segundos en esta galería. No crea ni modifica partidas.

Con **F5**, los trabajadores caminan, construyen, recuperan chatarra y transportan la carga. Recluta supervivientes y compra fusil, escudo, herramientas técnicas o botiquín para comprobar las otras profesiones. Los técnicos reparan; los médicos atienden; los guardianes golpean con el escudo; los tiradores disparan. Artilleros y saboteadores enemigos también usan las nuevas secuencias.

## Qué se sustituyó

Los aliados de campo y esos dos enemigos usaban una sola ilustración grande: el código movía pequeños recortes del torso y las piernas. Los civiles usaban otro dibujo único con un rebote. Ahora se reproducen fotogramas completos mediante `AnimatedSprite2D`. Los trabajadores comparten este sistema con su propio equipo.

Hay nueve diseños: tirador, guardián, técnico, médica, constructor, recuperador, superviviente, artillero y saboteador. Cada archivo contiene **72 fotogramas**, con reposo, marcha, daño, caída, cansancio, disparo, trabajo, transporte de carga, incorporación y protección. Huir reutiliza la marcha con su propia cadencia. El juego selecciona las acciones que corresponden a cada profesión; la galería permite inspeccionar todo el material.

Las poses de anatomía parten de un personaje original y siete clips nativos de PixelLab. Comparten esa base para mantener proporciones; los atuendos, cascos, telas, mochilas, herramientas y armas se editan como píxeles en LibreSprite. No son nueve generaciones independientes de anatomía. El arma del tirador, el escudo, las cruces médicas y los equipos industriales distinguen cada función. La ropa tiene movimiento secundario durante la marcha.

Se conserva el arte anterior en el repositorio. Las animaciones existentes del Portador y de los demás enemigos continúan disponibles; esta entrega sustituye los personajes de apoyo y los dos enemigos que dependían de la ilustración estática.

## Estados y reglas

- El desplazamiento selecciona la marcha; una herramienta activa selecciona trabajo, atención o ataque. Cargar chatarra tiene fotogramas propios.
- La reacción al daño tiene prioridad sobre el trabajo y la marcha. La caída tiene prioridad sobre todos los demás estados y termina sin reiniciarse.
- Caminar, trabajar y combatir acumula cansancio visual. Descansar recupera la respiración; el umbral de recuperación es distinto al de agotamiento para evitar cambios rápidos entre estados. Hay respiración agitada y sudor. Esto presenta el esfuerzo sin cambiar precios, velocidad física, daño o duración de las construcciones.
- Un aliado derrotado sale inmediatamente del grupo de combate. Se ve la caída y el superviviente se incorpora después; necesita otra herramienta para recuperar la profesión. Los trabajadores y civiles siguen las reglas de retirada de la colonia, sin añadirles una muerte permanente nueva.
- Los dos enemigos terminan su caída antes de desaparecer y dejan de ser una amenaza al llegar a cero de vida. Los dibujos no infligen daño ni crean recompensas.
- Durante los diálogos, pausa y expediciones, la animación sigue la suspensión del mundo. Todos los recortes comparten un apoyo en `(32, 56)` dentro de celdas de `64×64`: el equipo no atraviesa el suelo.

## Editar y reconstruir

Los archivos editables están en `assets/units/animated/sources/`. Abre cualquier `.ase` con LibreSprite: tiene capas **Cuerpo** y **Equipo**, etiquetas y tiempos por fotograma. `pose_reference.ase` conserva las poses comunes, por lo que la reconstrucción habitual funciona sin conexión ni nuevas generaciones.

Para reconstruir los atlas desde esa referencia:

```powershell
python tools/build_unit_sprites.py --libresprite "D:/descargas/libresprite-development-windows-x86_64/libresprite.exe"
```

La reconstrucción reemplaza los `.ase` de profesión y sus PNG derivados; conserva aparte cualquier retoque manual que quieras mantener. Python prepara documentos vacíos y metadatos. **El muestreo, el dibujo de píxeles, los cambios de atuendo y el guardado se ejecutan dentro de LibreSprite**, en `tools/libresprite_units.js`. La exportación de las hojas también la hace LibreSprite.

`tools/queue_unit_clips.py` documenta la preparación inicial de clips mediante el MCP ya configurado. Es una operación externa que puede consumir generaciones; no hace falta ejecutarla para jugar, editar los `.ase` o reconstruir. Los enlaces temporales, descargas y respuestas quedan en `.godot/`; no se guardan credenciales en el proyecto. Procedencia del personaje: `assets/units/animated/provenance.json` y `docs/ASSET_SOURCES.csv`.

## Comprobaciones

`tests/unit_animation_test.gd` comprueba poses distintas, movimiento de piernas, apoyo al suelo en todos los fotogramas, prioridad de estados, recuperación, ausencia de reinicio en la caída, paso de soldado a superviviente, validación del guardado y galería. La batería `tests/run_all.gd` contiene **38 suites**, incluidas las simulaciones de las cinco zonas. Las capturas quedan fuera de Git.

Referencias de herramientas: [LibreSprite](https://github.com/LibreSprite/LibreSprite), [formato ASE](https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md).

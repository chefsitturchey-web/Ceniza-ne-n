# CENIZA NEÓN — guía de arte v0.1

## Dirección común

Pixel art lateral de ruinas industriales cyberpunk. Oscuro, pero legible: grandes masas de sombra azul, metal frío, óxido mate y pequeñas luces funcionales. La colonia debe parecer reparada con piezas recuperadas; las máquinas enemigas, ensambladas en serie. Evitar saturar toda la escena de neón.

- Cámara lateral ortográfica, sin perspectiva isométrica. Personajes mirando a la derecha; el juego podrá reflejarlos.
- Resolución de juego: 640 × 360. Trabajar en píxeles enteros; escalado nearest-neighbor, sin suavizado.
- Personaje: lienzo de 48 × 48, cuerpo aproximado de 18 × 32. Pies anclados en (24, 44) en todos los cuadros.
- Enemigos: mismo lienzo y anclaje; silueta distinta por función.
- Muralla: 32 × 64. Torreta: 48 × 64. Núcleo: 96 × 96. Suelo: módulos de 32 × 32.
- Contorno selectivo de un píxel oscuro; dos o tres tonos por material. Luz principal arriba a la izquierda. Nada de texto dentro de los sprites.
- El color se acompaña de formas: visor rectangular aliado, ojo triangular enemigo, aviso de ataque con símbolo y animación.

| Uso | Color |
|---|---|
| Sombra profunda | #0B1322 |
| Fondo y metal oscuro | #182639 / #304356 |
| Metal iluminado | #8299A8 |
| Energía aliada | #47DACB |
| Construcción, advertencia | #FFCE75 |
| Enemigo y daño | #DD6482 |
| Óxido y corredor | #E89E54 |
| Recuperadores, marcas de obra | #B075AE |

## Cómo mantener consistencia en otra herramienta

Genera primero un único cuadro maestro del protagonista y apruébalo. Usa esa imagen como referencia visual en cada solicitud posterior; no vuelvas a inventar su aspecto en cada animación. Conserva modelo, configuración y semilla cuando la herramienta lo permita. Una semilla por sí sola no asegura consistencia.

Los tamaños siguientes son objetivos de entrega. Si tu generador solo produce imágenes grandes, pide una referencia limpia de un único sprite; después habrá que reducir, limpiar píxeles y ajustar el anclaje en un editor de pixel art. No asumas que una imagen grande con apariencia pixelada ya es un sprite terminado. Comprueba que el PNG tenga transparencia real, no un tablero dibujado.

## Prompt base (anteponer a todas las solicitudes)

> Create a production reference for CENIZA NEON, an original side-view 2D pixel-art industrial cyberpunk survival game. Orthographic side view, readable silhouettes at 640x360 gameplay resolution, crisp square pixels, selective one-pixel dark outlines, two or three shades per material, restrained detail, upper-left lighting. Post-collapse machinery, salvaged steel, matte rust, dark navy shadows. Palette: #0B1322 #182639 #304356 #8299A8 #47DACB #FFCE75 #DD6482 #E89E54 #B075AE. Cyan is reserved for friendly powered equipment, pink-red for enemy sensors, amber for warnings. Transparent background for isolated assets. No text, no watermark, no mockup, no UI, no perspective, no isometric view, no photorealism, no smooth gradients, no antialiasing, no painted checkerboard, no excessive bloom. Match the attached approved reference whenever provided.

## Primera tanda: lo que necesitamos antes que nada

No hace falta generar todas las animaciones todavía. Empieza por estos tres cuadros maestros y compártelos para revisar escala y silueta antes de producir las hojas.

### 1. Portador — `player_master.png`

Añadir al prompt base:

> One original human neural-key carrier, full body, facing right, neutral standing pose. Short charcoal utility jacket, compact steel shoulder plate, dark trousers, heavy boots, small amber rectangular visor, one cyan power cell on the upper back. Wields a short blunt industrial cutting blade, lowered and held close to the body. No cape, no flowing scarf, no gun, no oversized armor. Athletic practical silhouette, visually distinct head, torso and legs. Target sprite canvas 48x48 pixels, body approximately 18x32 pixels, feet anchored at pixel (24,44). One character only, centered with space for later attack animation.

### 2. Errante conectado — `enemy_walker_master.png`

> One original hostile bipedal maintenance robot, facing right, neutral standing pose. Hunched rectangular steel torso, narrow mechanical legs, one triangular pink-red sensor, one heavy blunt claw. Exposed cables stay close to the body. Dark cold steel with sparse rust. Slower and wider silhouette than the human reference. Target canvas 48x48 pixels, body approximately 24x30 pixels, feet anchored at (24,44). No cyan lights. One enemy only.

### 3. Corredor — `enemy_runner_master.png`

> One original hostile low-slung two-legged courier robot, facing right, poised to sprint. Forward-leaning wedge body, long angular spring legs, compact amber-rust plating and one pink-red sensor. Clearly shorter and leaner than the maintenance robot reference. Target canvas 48x48 pixels, silhouette approximately 30x22 pixels, feet anchored at (24,44). No cyan lights. One enemy only.

## Segunda tanda: escenario y colonia

Generar cada elemento por separado sobre transparencia.

**Muralla — `wall_01.png`:**
> A single repaired defensive barricade made from vertically bolted salvaged steel plates, dark braces, small amber construction marks, sturdy readable rectangular silhouette. Side-view gameplay asset, target canvas 32x64 pixels, ground contact on bottom row. No surrounding scenery and no guns.

**Torreta — `turret_01.png`:**
> A single friendly automatic ballistic turret facing right, squat rotating gun housing on a narrow steel pedestal, one small cyan status light, salvaged industrial construction matching the wall reference. Target canvas 48x64 pixels, ground contact on bottom row. No projectile and no muzzle flash; those are separate effects.

**Núcleo — `core_01.png`:**
> A single colony power-and-neural relay, compact armored industrial cabinet with reinforced base, central vertical amber chamber, two small cyan conduits, asymmetrical repair plates, recognizable safe-home silhouette. Side view, target canvas 96x96 pixels, ground contact on bottom row. No lettering, no people, no scenery.

**Suelo — `ground_strip.png`:**
> A seamless horizontally tileable side-view ground strip of cracked industrial pavement above dark rubble, target 128x32 pixels. Continuous flat walkable top edge, visually quiet upper surface, darker underside. No foreground props, no perspective, no bright lights. Left and right edges must match.

**Fondo lejano — `background_far.png`:**
> A horizontally tileable distant skyline for a side-scrolling game, target 640x360 pixels. Abandoned industrial towers, collapsed transit structures and sparse dim windows. Low contrast navy silhouettes, strongest detail in the lower half, empty dark sky in the upper third for HUD readability. Flat side view, no characters, no ground gameplay layer, no text, no bright cyan or pink foreground accents. Opaque background.

## Animaciones, después de aprobar los maestros

Personaje: reposo 4 cuadros, correr 6, ataque 6, esquiva 4, daño 2, muerte 4. Errante y corredor: caminar 6, ataque 6 (tres de anticipación, uno de golpe, dos de recuperación), daño 2, muerte 4.

Prompt de continuidad:

> Using the attached approved master sprite as an exact character reference, create ONLY the [ANIMATION] sequence in [N] frames, arranged in one horizontal row of equal 48x48 cells. Preserve the exact outfit, palette, body proportions, weapon, lighting, and pixel density. Fixed camera, facing right, feet baseline y=44 and resting pivot x=24 in every cell. No duplicate poses, no frame labels, no grid lines, no cropping, no extra characters. Transparent background. The animation must read clearly at native size. [Describe the individual poses here.]

Para correr: contacto derecho, descenso, paso, contacto izquierdo, descenso, paso. Para atacar: preparar, levantar arma, anticipación máxima, corte al frente, seguimiento, retorno. Estas son indicaciones de pose, no una garantía de que el generador entregue una hoja lista: revisaremos cantidad de cuadros y continuidad.

Los efectos de sobrecarga y disparo seguirán siendo código hasta integrar personajes y estructuras. El constructor y recuperador pueden derivarse del maestro humano con herramienta/ mochila y colores distintos; no necesitan un sistema artístico nuevo.

## Entrega

Guardar originales y PNG aprobados por separado. No integrar una hoja sin revisar el tamaño real, transparencia, anclaje, dirección y consistencia cuadro a cuadro. Registrar herramienta, fecha, referencia utilizada y condiciones de uso de cada recurso en `docs/ASSET_SOURCES.csv`. La primera tanda no bloquea el prototipo actual.

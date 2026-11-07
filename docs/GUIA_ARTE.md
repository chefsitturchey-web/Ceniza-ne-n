# CENIZA NEÓN: guía de arte actual

## Dirección común

Conservar la dirección industrial del proyecto: ruinas cyberpunk legibles, sombras azul oscuro, acero frío, óxido mate y pequeñas luces funcionales cian/ámbar. La colonia usa vista lateral; las arenas, vista cenital; los retratos, ilustración manga a color. No aplicar una única cámara o cuadrícula a todos los recursos.

| Uso | Color de referencia |
| --- | --- |
| Sombra | `#0B1322` |
| Fondo y metal | `#182639`, `#304356`, `#8299A8` |
| Energía aliada | `#47DACB` |
| Construcción y aviso | `#FFCE75` |
| Amenaza y daño | `#DD6482` |
| Óxido | `#E89E54` |
| Recuperadores y obra | `#B075AE` |

La base lógica es 640 × 360 (`project.godot`). La pantalla puede ampliar su ancho por `keep_height`. Conservar píxeles nítidos, transparencia real, apoyo al suelo y lectura a la escala final.

## Recursos ya integrados

- Portador lateral/cenital y cinco jefes: `assets/characters/combat/layout.json` define celdas, anclajes, escalas y secuencias. `CombatSpriteLibrary` y `CombatFlipbook` los reproducen. Los PNG activos usan celdas de 192 × 192 para Portador, 320 × 320 para los tres autómatas y 144 × 144 para Prefecto y Madre; no reutilizar el antiguo objetivo universal de 48 × 48.
- Profesiones y unidades: `UnitSpriteLibrary` carga nueve variantes de celdas 64 × 64 desde `assets/characters/units/`. El Errante conserva sus secuencias propias en `assets/characters/enemies/`.
- Construcciones: `ArtScale`, `data/art_bounds.gd` y `data/art_bounds.json` definen recortes y apoyo. Núcleo, murallas y torretas tienen niveles. No reemplazar recortes explícitos por divisiones uniformes del atlas.
- Escenario: capas y fuentes en `assets/world/backgrounds/`; máscaras en `masks/`. `AnimatedBackdrop` y `backdrop_motion.gdshader` animan partes de las pinturas.
- Retratos: `assets/characters/portraits/`, con retratos de jefes y especificaciones en `assets/characters/portraits/bosses/prompts.json`.

## Especificar una variante o recurso nuevo

Las siguientes son pautas de entrega si se solicita arte nuevo; no son una lista de producción pendiente. Usar como referencia el recurso aprobado que se vaya a ampliar y conservar rostro, ropa, equipo, materiales y escala.

**Personaje:** personaje original industrial posapocalíptico, silueta completa, orientación y cámara iguales a la variante del proyecto, transparencia real, sin texto ni cuadrícula pintada. Mantener los anclajes y el orden de etiquetas de su `layout.json`. Describir poses individuales y revisar continuidad antes de integrar.

**Estructura:** pixel art lateral ortográfico, acero oscuro y cobre oxidado, tuberías y remaches, luces cian/ámbar contenidas, base completa sobre el suelo, sin perspectiva isométrica ni texto. Mantener materiales reconocibles entre niveles. Separar cabezal y pedestal cuando el controlador los articule.

**Retrato:** manga a color, contorno de tinta variable, sombras de borde duro, rostro expresivo y mecánica funcional; fondo transparente y sin marco. Conservar la identidad de los retratos actuales y consultar la referencia de tinta en `docs/references/`.

**Fondo:** panorama lateral industrial, siluetas limpias, profundidad por capas, espacio legible para juego y HUD; especificar qué partes deben ser transparentes y cuáles recibirán máscaras de animación.

## Editar y comprobar

Las fuentes ASE y los metadatos se conservan junto a los PNG. El Portador lateral, Prefecto y Madre tienen integraciones posteriores con PixelLab: sus PNG activos no se reconstruyen únicamente exportando los ASE originales. Consultar la guía de combate antes de regenerarlos. Las herramientas de `tools/art/` preparan, montan o exportan; revisar su comportamiento de sobrescritura antes de regenerar. No todas protegen ediciones del mismo modo. Los archivos separados de marcha son copias de edición y no actualizan automáticamente el atlas del juego.

Probar con F6 en `levels/story/combat_animation_preview.tscn` y `unit_animation_preview.tscn`; F5 muestra escala de colonia y F1 abre jefes en editor/depuración. Revisar transparencia, suelo, dirección y continuidad. Registrar procedencia en `docs/art/ASSET_SOURCES.csv`.

[Combate ilustrado](art/ARTE_COMBATE_ILUSTRADO.md) · [Personajes](art/PERSONAJES_Y_ANIMACIONES.md) · [Fondos](art/FONDOS_EN_CAPAS.md) · [Novela](art/NOVELA_VISUAL_Y_COHERENCIA.md).

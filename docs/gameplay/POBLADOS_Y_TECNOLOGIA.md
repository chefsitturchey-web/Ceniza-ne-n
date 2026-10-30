# Poblados y tecnología recuperable

Las cinco colonias conservan sus 14.400 píxeles de ancho. Ahora el recorrido contiene veinte conjuntos de edificios abandonados por distrito: fachadas de varias plantas, comercios dañados, tejados abiertos, cableado y letreros propios de cada zona. La ropa responde al viento; hay humo, ventanas iluminadas, farolas y reflejos. La decoración permanece detrás de las construcciones y no bloquea el movimiento.

Las parcelas despejadas muestran siluetas discretas de muralla o torreta para distinguir dónde expandir el perímetro. Siguen usando el sistema existente de constructores, núcleo y energía.

## Tres instalaciones recuperables

| Instalación | Primer nivel | Segundo nivel | Núcleo requerido |
|---|---|---|---|
| Taller de reconstrucción | Construcción +25 % | Construcción +50 % | Nv.1 / Nv.3 |
| Armería del distrito | Daño de tropas y torretas +15 % | Daño +30 % | Nv.2 / Nv.3 |
| Dispensario comunitario | Cura 3 de vida/s | Cura 6 de vida/s | Nv.2 / Nv.3 |

El taller acelera el trabajo real en núcleo, defensas, instalaciones y despejes; no modifica la velocidad de marcha. La armería mejora el daño de las unidades y torretas de colonia, incluyendo el asalto de portales. El dispensario cura al Portador, soldados y trabajadores vivos dentro de 260 píxeles; no revive bajas. Las bonificaciones no se apilan al recargar y pertenecen al distrito. Las arenas y las estadísticas de ataque de sus personajes permanecen como estaban.

La recuperación también cambia el barrio: ventanas iluminadas, fachadas más claras, banderas, ropa renovada y pulsos en el cableado. El primer nivel activa los bloques cercanos; el segundo extiende la recuperación visual hasta 900 píxeles. Los sectores conectados se identifican con «RED». Este alcance visual no amplía la curación del dispensario, que sigue limitada a 260 píxeles.

## Repartos del taller

Un taller recuperado activa un transportador automático de suministros. Recorre físicamente el camino entre taller y núcleo, con carga visible y ruedas que giran con el desplazamiento. Entrega como máximo dos repartos por día: cada uno aporta 2 piezas y 8 de chatarra en nivel 1, o 4 piezas y 12 de chatarra en nivel 2. Las piezas se descargan en el depósito, sin ocupar la mochila.

El transportador espera si detecta enemigos en la ruta; de noche se recoge en el refugio más cercano y no inicia recogidas. Puede terminar una entrega si alcanza el núcleo con carga. Es un vehículo logístico, no una unidad de combate. Su posición, carga, espera y entregas realizadas se guardan para evitar premios duplicados al cargar. El estado del reparto aparece en **L → Poblados**.

## Componentes especiales y costes

Hay seis depósitos técnicos por distrito: dos servomotores, dos bobinas de inducción y dos membranas filtrantes. Cada uno entrega su componente una sola vez. No dependen de una tirada aleatoria; se necesita núcleo encendido y liberar el tramo si lo controla un portal. Mantén E durante 2,5 segundos para recuperarlos.

Los componentes se guardan en un estuche técnico protegido: no ocupan las 24 plazas de piezas normales ni se rompen al desbordar la mochila. Cada restauración o mejora consume uno de su tipo.

| Instalación | Restauración | Mejora |
|---|---|---|
| Taller | 1 servo + 8 piezas + 35 chatarra | 1 servo + 12 piezas + 65 chatarra |
| Armería | 1 bobina + 12 piezas + 50 chatarra | 1 bobina + 16 piezas + 80 chatarra |
| Dispensario | 1 filtro + 10 piezas + 40 chatarra | 1 filtro + 14 piezas + 70 chatarra |

Mantén E en la instalación para encargar el trabajo. Los materiales se reservan al aceptar la orden; un constructor debe desplazarse y trabajar. Restaurar requiere 30 segundos de trabajo y mejorar 45, antes de aplicar bonificaciones o colaboración. Una petición bloqueada no consume materiales. Las instalaciones son puntos de apoyo permanentes del distrito; su bonificación se conserva mientras continúas allí.

## Cómo encontrarlos y probar

Pulsa **L → Poblados**. El catastro muestra ubicaciones reales, estado, componentes disponibles y bonificaciones; «Historia» vuelve al relato. El HUD añade **TEC** con el número de componentes y un resumen al pasar el cursor por el inventario.

Puedes usar **Continuar**: los checkpoints anteriores incorporan instalaciones dormidas y depósitos sin abrir, conservando sus piezas y edificios. La colocación reserva espacio alrededor de parcelas, botín y misiones; al migrar se consulta el botín ya restaurado. Las restauraciones, mejoras, existencias y depósitos abiertos se guardan. Las instalaciones y su tecnología son locales: el tren conserva el traslado de piezas normales de la mochila, pero no transporta estas bonificaciones.

La validación dirigida utiliza `settlement_world_test`, con restauración mediante trabajadores, daño real de torretas, velocidad de obra, curación local, guardado y compatibilidad en las cinco zonas. `frontier_progression_test` conserva la comprobación del núcleo, parcelas y mochila. Las capturas se revisan con `validate.ps1 -Suite settlement_world_test -Capture` y quedan en `build/validation/latest/`, fuera de Git.

## Arte editable

Los atlas están en `assets/world/settlements/`, con fuentes en `sources/*.ase`: diez fachadas, seis versiones de instalaciones y tres componentes. Se ensamblan y dibujan dentro de LibreSprite mediante `tools/art/libresprite_settlements.js`, reutilizando píxeles del atlas industrial aprobado y añadiendo plantas, daños, ventanas, mecanismos y detalle. No se modifican las imágenes originales. `build_settlement_art.py` prepara documentos vacíos y exporta los PNG con LibreSprite; se detiene si encuentra una fuente editable existente.

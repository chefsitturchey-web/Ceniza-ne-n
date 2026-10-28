# Revisión y bloque de progresión — 28/10/2026

Este documento registra el primer bloque. Avances posteriores: `MENU_Y_OPCIONES.md`, `MODULOS_Y_EVOLUCIONES.md` y `SILUETAS_MECANICAS.md`; los pendientes de esta revisión deben leerse junto con esas entregas.

## Entregado

- Datos neuronales: una máquina derrotada por cualquier aliado entrega un dato; seis datos dan un punto. La recompensa solo se registra una vez.
- Clínica en x=-110, a la izquierda del núcleo: mantener E de día abre tres elecciones, detiene el mundo y permite teclado, ratón o mando. Esc/Start devuelve el control. Las mejoras se guardan al instalarlas, si la persistencia está habilitada.
- Filo de inducción: +10 de daño por rango, hasta tres. Se suma al daño del Inspector, sin sobrescribirlo, y viaja a la arena.
- Dron perforador: +4 de daño y reducción del intervalo base del 10% por rango, hasta tres. Una reducción del intervalo del 30% equivale a aproximadamente un 43% más de disparos por segundo.
- Capacitor sináptico: +5 de resistencia por segundo por rango, hasta tres. También funciona contra el jefe.
- Compatibilidad con guardados previos: ausencia de datos neuronales significa cero mejoras; documentos corruptos se rechazan antes de aplicar cambios.
- Siete efectos de Kenney, dos stems originales sincronizados y buses Music/SFX con compresor y limitador. Música tranquila de día, percusión en aviso/noche y expedición; atenuación en pausa. M silencia música y efectos. Avisos sonoros de ataques y choque del jefe, esquiva, golpes, disparos, destrucción y mejora.
- Ceniza y brasas ambientales, reflejos estilizados de personajes y farolas, brillo de disparos, dron con propulsores e indicadores de rango. Escudo remachado del Blindado, pistón del Ariete, resortes y toberas del Saltador, carga metálica del recuperador. Se conservan los sprites y animaciones anteriores.

## Prueba manual

1. Abrir `project.godot` y pulsar F5. Se conservan velocidad 220, daño 50 y ciclo 10/10/60.
2. Construir las defensas y derrotar seis máquinas: aparece el aviso de punto neuronal. Las bajas de torretas y del dron también cuentan.
3. Al amanecer, acercarse al pequeño terminal con cruz situado a la izquierda del núcleo. Mantener E. Elegir una mejora; cada una cuesta un punto y tiene tres rangos. Las flechas/cruceta y Enter/A permiten usar el panel sin ratón.
4. Cerrar con Esc/Start y comprobar el efecto. Salir y volver a abrir conserva el último guardado de día; instalar en la clínica actualiza ese guardado.
5. Escuchar las fases, disparos y esquivas. Pulsar M para silenciar. Observar farolas, reflejos y ceniza durante la noche. Viajar al jefe para verificar el filo y el capacitor.

## Qué falta, por prioridad

1. Animaciones verticales reales del Portador y siluetas finales propias para Blindado, Saltador y Ariete. Los detalles de esta entrega ayudan a distinguir funciones, pero sus animaciones todavía derivan de Errante/Corredor. No se han creado hojas de animación nuevas.
2. Producción musical final, variaciones de impactos por material, pasos por superficie, ambiente industrial y mezcla auditiva con altavoces y auriculares. La música incluida es una composición sintética de trabajo, no una banda sonora terminada ni aprobada por el músico del equipo.
3. Opciones persistentes de volumen, resolución y accesibilidad; menú inicial y elección explícita entre continuar/nueva partida.
4. Nuevos módulos automáticos y evoluciones con decisiones entre armas, energía y defensa. El dron de esta entrega mejora el módulo automático que ya existía.
5. Distritos 2–4 y jefes posteriores, progreso entre distritos y cierre narrativo. El botón Continuar del primer jefe sigue reiniciando como en el proyecto original.
6. Ajuste de dificultad con jugadores: las pruebas automatizadas conservan el balance sin mejoras, pero no miden si las elecciones resultan divertidas ni si los tiempos de diez segundos permiten aprender cómodamente.

## Herramientas y fuentes revisadas

- La búsqueda mediante Plugin Management no encontró un generador de música/SFX utilizable entre los resultados. Descript figura conectado, pero su edición audiovisual no resuelve directamente la producción de assets de audio para este juego. No se instalaron plugins ni se usaron credenciales.
- [Kenney Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds): CC0. Descarga alternativa del mismo paquete en [OpenGameArt](https://opengameart.org/content/sci-fi-sounds). Licencia original y nombres de archivos conservados en `assets/audio/sfx/KENNEY_LICENSE.txt` y `ASSET_SOURCES.csv`.
- [Godot Sound Manager](https://github.com/nathanhoad/godot_sound_manager): repositorio consultado como alternativa; no incorporado. La integración usa nodos nativos para conservar las sesiones independientes del proyecto y evitar otra dependencia.
- [Buses de audio de Godot](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html): referencia para separar música/efectos y mantener margen en la mezcla.
- [ElevenLabs Sound Effects](https://elevenlabs.io/docs/overview/capabilities/sound-effects): candidato para producir ambientes y efectos a medida. No está conectado ni se han generado archivos con ese servicio. Hay que revisar condiciones de uso del plan antes de incorporar resultados.

## Especificaciones para producción externa

Mantener la paleta y el prompt base de `GUIA_ARTE.md`. Generar cada personaje por separado usando los sprites existentes como referencia. Lateral ortográfico, derecha, transparencia real, píxeles sin suavizado, anclaje idéntico entre cuadros; sin bloom pintado. Revisar primero una pose maestra antes de pedir animaciones.

- Blindado: lienzo 48×48, pies (24,44), robot compacto con torso ancho de acero azul, escudo vertical remachado de unos 8×28 a su derecha y sensor rosa triangular. Nada de luces cian. Movimiento pesado; el escudo conserva su posición frontal.
- Saltador: lienzo 48×48, pies (24,44), robot bajo con patas de resorte largas, toberas traseras y placas de óxido. Anticipación agachándose, compresión de muelles, vuelo y aterrizaje distintos. Evitar que la silueta se confunda con el Corredor.
- Ariete: lienzo 64×64, pies (32,60), mantenimiento pesado con pistón frontal y cabeza de impacto de acero. Cuerpo ancho, juntas visibles y marcas ámbar; sensor rosa. Preparación en retroceso, carga y recuperación claramente separadas.
- Animaciones por personaje: reposo 4, caminar 6, ataque 6, daño 2, destrucción 4; Saltador añade agacharse 3, salto 4, aterrizar 3. Entregar PNG individuales o atlas con metadatos; no aceptar un atlas generado sin revisar el número y alineación de celdas.

Prompt musical para el músico o generador:

> Original industrial cyberpunk survival score, 100 BPM, D minor, 4/4, 16 bars, exactly 38.4 seconds. Melancholic ruined city, restrained analog pads, muted metallic plucks, deep controlled bass, dry industrial percussion. No vocals, no recognizable melodies from existing works, no trailer risers, no abrupt ending. Deliver two sample-aligned seamless stems of identical length: exploration harmony/atmosphere and additive siege rhythm/bass using the same harmonic progression. Leave space for combat transients. Stereo 48 kHz, 24-bit WAV, no clipping, true peak below -1 dBTP. Include a separate full-mix preview. No loudness normalization per stem that destroys their intended relative balance.

Prompts de SFX (cada uno aislado, sin música, sin voces ni ambiente de fondo):

- Corte: `Short heavy industrial blade swish with restrained electrical edge, 0.25 seconds, dry, clear transient, no explosion.` Tres variaciones.
- Impacto: `Salvaged steel armor struck by a blunt cutting blade, short dense metal impact, 0.35 seconds, no long cinematic tail.` Cinco variaciones, más una versión de escudo.
- Esquiva: `Compact suit servo burst and cloth movement, low mechanical whoosh, 0.22 seconds, no gunshot.` Tres variaciones.
- Clínica: `Neural link accepted, restrained ascending three-note electronic confirmation, warm cyan technology, 0.7 seconds, not a UI error beep.`
- Ambiente: `Abandoned industrial district at night, distant ventilation, fine airborne ash and occasional far metal creaks, no voices, no close impacts, seamless 30-second loop.`

SFX mono 48 kHz/24 bits WAV, transitorios conservados, inicio limpio sin silencio perceptible, pico ≤-3 dBFS, sin clipping y colas con fundido. Mantener WAV maestros fuera de exportaciones; convertir a Ogg para integración. Las especificaciones de pico son objetivos de entrega, no una certificación de la mezcla actual.

## Validación y límites

`tests/run_all.gd`: 17 suites, incluyendo 45 comprobaciones nuevas; simulaciones sin mejoras de 128.6 s y 240.5 s. Capturas opcionales: ejecutar `tests/neural_audio_test.gd -- --capture` con render gráfico; se escriben en `.godot/`, fuera de Git. Se revisaron las capturas de clínica y distrito nocturno con OpenGL en GTX 1070.

La comprobación estática de scripts emite al cerrar un aviso de cuatro referencias ObjectDB y un recurso `debris_emitter.gd`. Se reprodujo el mismo aviso en una copia limpia de HEAD anterior a estos cambios (65 scripts); no se cambió la prueba para ocultarlo. El resto de pruebas de ejecución de esta entrega cierra sin ese aviso. El ejecutor histórico lee el log de Godot, que no incluye siempre esos mensajes finales de stderr: su total de suites no certifica ausencia de avisos de cierre. Queda pendiente corregir esa limitación del ejecutor.

Los archivos musicales se generan de forma reproducible con `python tools/generar_musica.py` (NumPy y FFmpeg). Ambas capas miden 38.4 s y se importan en bucle a 100 BPM. Los SFX se recortan con fundidos y se convierten a mono usando `python tools/preparar_sonidos.py ruta/al/sci-fi_sounds.zip`: esquiva de 0.22 s, corte de 0.28 s y los demás efectos por debajo de 0.8 s. Se verifica decodificación y duración; falta escucha y aprobación artística del equipo. No se reemplazaron los sprites existentes ni se publicó contenido en un remoto.

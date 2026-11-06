# Primeros pasos, impacto y rondas

F5 y Nueva partida: la primera campaña comienza jugando, sin la explicación modal ni la conversación de entrada. Una línea y una flecha guían movimiento, extracción de 12 piezas, núcleo, dos murallas, despeje, generador, otras 10 piezas, núcleo Nv.2, dos torretas y primera noche. Cada paso entrega 8 de chatarra una sola vez. Mantén la tecla mostrada; respeta las reasignaciones. En táctil aparece el icono de toque. El icono nocturno indica espera mientras trabaja el constructor. A los 8 segundos sin movimiento, recogidas ni progreso de obra, la pista parpadea.

Opciones > Reiniciar guía permite repetirla, también desde el menú para la próxima partida. La guía, siete logros y el récord se guardan mediante SaveSystem en `user://progreso_pixel.cfg`, separados del checkpoint de campaña. Nueva partida conserva ese perfil. Las escenas de práctica y las suites no otorgan premios de progreso por defecto.

Los impactos muestran daño y sacuden brevemente la cámara; matar detiene el tiempo durante 55 ms. La recogida muestra cantidades y pequeñas piezas que vuelan hacia el contador inferior. Todos usan las fuentes pixel existentes. Opciones > Reducir destellos y sacudidas desactiva también el hit-stop. Partículas controla las piezas voladoras. No hay barras de vida nuevas en el mundo.

Las bajas de las tropas cuentan para el comandante. Encadena bajas en 2,5 s para recibir hasta cinco veces la chatarra base. La meta de cada noche es conseguir 10 bajas y llegar al amanecer sin perder murallas: premio de 25 de chatarra. El resultado muestra bajas, mejor cadena, chatarra ganada, récord y de una a tres estrellas dibujadas con un recurso propio. Seguir conserva la campaña; Otra vez recarga rápidamente el último amanecer guardado. La expedición y sus pantallas de victoria mantienen su flujo.

Logros: primera baja, diez bajas, cincuenta bajas, cadena de tres, doble muralla, primer amanecer y defensa perfecta. Los avisos se muestran en cola para que ninguno tape al anterior.

## Archivos y pruebas

Tras los 11 pasos aparecen consejos de una sola vez: diario, reclutamiento en los campamentos, herramientas y armas en el Arsenal (x=-600), ampliacion del refugio, asalto a portales y sobrecarga nocturna. La flecha indica el destino; para asaltar, situate en el lado del portal y pulsa la accion de escolta, que tambien ordena retirada. Reclutar cuesta 5 de chatarra; las herramientas compradas dan oficio a los habitantes disponibles. Cada consejo resuelto entrega 4 de chatarra. Si lo ignoras durante 45 segundos deja paso al siguiente sin premio. Los consejos usan la clave `tips` del perfil; los pasos antiguos `guide` conservan sus numeros.

Los avisos cambian al ultimo teclado o mando usado y respetan los remapeos. Opciones > Avisos de teclas permite Automatico, Teclado o Mando; el tactil conserva sus iconos. La columna superior mide cartel, objetivo, nivel y barra, plataforma, meta nocturna y veneno. El combo queda debajo, tambien si un nombre largo obliga al cartel a ocupar varias lineas.

`tests/ui_guidance_test.gd` comprueba dispositivos, remapeos en pausa, tactil, compatibilidad y progreso de consejos, y las ocho combinaciones de guia, noche y combo. Las capturas de revision estan en `build/capturas/ui_guia/`.

- `systems/first_steps.gd` y `ui/first_steps_hud.gd`: objetivos y marcador.
- `components/impact_feedback.gd`: números, vuelo de recursos, sacudida e hit-stop.
- `systems/round_engagement.gd` y `ui/round_rewards_hud.gd`: combos, meta, resultados y logros.
- `tests/first_steps_test.gd`, `tests/impact_feedback_test.gd`, `tests/round_engagement_test.gd` y `tests/guide_walkthrough_test.gd`: registradas en `tests/run_all.gd`.

Validar con `tools/maintenance/validate.ps1 -GodotPath <ejecutable de consola>`. Registros en `build/validation/latest/`. Para probar manualmente: reinicia la guía en Opciones, entra a una colonia, sigue la flecha manteniendo la tecla, deja de actuar 8 s y comprueba la pista. Construye antes de adelantar la noche. Comprueba el combo con varias bajas próximas, el resultado al amanecer y los efectos con accesibilidad activada y desactivada.

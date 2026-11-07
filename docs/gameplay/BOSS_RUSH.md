# Boss Rush

**F5 → Boss Rush** encadena Recaudador, Santa Caldera, Coro Sumergido, Prefecto y Madre Cero, en el orden de `CampaignRoute`. `levels/expedition/boss_rush.gd` crea la arena compartida con `rush = true`: no reproduce entrada ni desenlace de novela visual y oculta su botón narrativo. La campaña no se carga ni se guarda desde este modo.

El cronómetro avanza solo durante el combate activo: excluye pausa, cierre del encuentro e intermedios. Se acumulan los golpes recibidos. Tras cada victoria intermedia se recupera el 50 % de la vida máxima, sin superar el máximo; el siguiente jefe añade 15 de daño de filo por etapa. El intermedio permite seguir o abandonar. Una derrota termina la ruta; los resultados permiten reintentar o volver al menú.

## Ranking local

El archivo independiente `user://boss_rush.cfg` conserva las **diez mejores victorias por tiempo**, con nombre y golpes. Los resultados muestran el **top 5**. Si la victoria entra en el ranking, se puede editar el nombre de hasta 12 caracteres; Intro o salir/reintentar guarda el cambio. Una derrota no añade una marca. El lector admite el antiguo récord sin nombre como «Portador».

La escritura usa un archivo `.tmp` y renombrado.

## Ranking online

`levels/expedition/online_ranking.gd` (`OnlineRanking`) envía cada victoria a `https://ceniza-neon.chefsitturchey.workers.dev/api/ranking` (Worker de Cloudflare con D1, código en el repo `ceniza-neon-web`, carpeta `worker/`). Nunca bloquea el juego:

- Al salir o reintentar tras una victoria, la marca se añade a la cola `user://boss_rush_online.cfg` y se intenta enviar. Sin red queda en cola; se reintenta al abrir el Boss Rush.
- Una respuesta 2xx o un 4xx (salvo 429) saca la marca de la cola; errores de red o 5xx la conservan.
- Los resultados muestran el top 3 online («conectando…», «sin conexión» o «aún vacío»). La página de descarga de la web muestra el top 20.
- En pruebas headless la red está desactivada (`OnlineRanking.enabled`).
- El servidor valida nombre (1–12), tiempo (30 s–4 h) y limita 20 envíos por hora por IP. Android necesita el permiso `INTERNET` (activo en `export_presets.cfg`).

Limitación conocida: si se cierra el juego con la pantalla de resultados abierta, esa victoria no se encola.

## Probar

Entrar desde el menú, pausar para comprobar el reloj, vencer un jefe y observar curación y mejora del filo. Completar la ruta para registrar tiempo y nombre; reabrir el modo para comprobar persistencia. Las pistas cortas y los controles adaptativos funcionan en estas arenas.

`tests/boss_rush_test.gd` comprueba flujo y ranking; `tests/story_flow_test.gd` comprueba la exclusión narrativa. Se ejecutan con `tools/maintenance/validate.ps1` dentro de las 67 ejecuciones de `tests/run_all.gd`.

[Historia](HISTORIA_FLUJO.md) · [Tácticas y pistas](JEFES_TACTICAS_Y_ARENAS.md).

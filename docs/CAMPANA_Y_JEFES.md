# Tres distritos conectados

Bloque jugable del 28 de octubre de 2026: Periferia oxidada → Fundición → Barrio inundado. Cada distrito tiene colonia lateral, dos repetidores, estación y jefe cenital. Los distritos restantes del GDD siguen pendientes; este bloque termina después del Coro.

## Progresión y guardado

Al vencer al jefe aparece **Viajar a…**. Conservas puntos y mejoras neuronales, módulos, pasivas, evoluciones, núcleos de enlace y los roles de tus habitantes. Llegas con vida y resistencia completas, estructuras nuevas sin construir y 90 de chatarra más hasta 40 del excedente anterior. Los repetidores y el tren pertenecen a la nueva zona y deben desbloquearse otra vez.

La victoria guarda primero un documento de llegada: si vuelves al menú, **Continuar** te lleva al distrito desbloqueado. El primer guardado allí lo convierte en una instantánea completa. No se guardan referencias a los nodos de la escena anterior. Los guardados anteriores sin campo de campaña siguen correspondiendo a la Periferia.

En Fundición y Barrio inundado, perder el núcleo conserva el último amanecer; **Reintentar** restaura ese checkpoint. La primera zona conserva su reinicio desde cero. Abrir otra colonia con F6 no sobrescribe una partida perteneciente a un distrito distinto. No se publica nada en un remoto.

| Zona | Preparación diurna | Terreno | Jefe |
|---|---|---|---|
| Periferia oxidada | 10 s, ajuste existente | Suelo original | El Recaudador |
| Fundición | 45 s | Cuatro rejillas; aviso de 1.2 s, calor de 1.8 s y descanso; solo queman de noche | Santa Caldera |
| Barrio inundado | 50 s | Charcos que reducen los pasos al 82 %; la esquiva mantiene su impulso | El Coro Sumergido |

Las defensas de las zonas nuevas están más separadas. Se duplican sus recursos antes de ajustar las posiciones y los tiempos, para conservar los del primer distrito. Las oleadas reutilizan combinaciones más fuertes de los cinco enemigos existentes.

## Jefes

**El Recaudador** conserva sus estadísticas y patrones. Ahora explica su ataque actual, dibuja el corredor de la embestida y señala la segunda fase. El abanico de aviso representa los siete disparos de su segunda fase.

**Santa Caldera** tiene 8500 de vida. Alterna franjas verticales y horizontales con aviso antes del calor, abre el núcleo durante una purga de cuatro segundos y después lanza tres abanicos con aviso. La armadura recibe el 35 % del daño; la purga recibe el doble. Al 50 % de vida aumenta el ancho de las franjas y el número de proyectiles. Su cuerpo tiene compuertas que deslizan, rejillas, pistones y vapor al abrir.

**El Coro Sumergido** tiene 9000 de vida y tres antenas. El cuerpo bloquea daño hasta romperlas con ataques manuales: los módulos no resuelven ese objetivo por sí solos. Respeta alcance, dirección y coberturas. Romper los tres enlaces elimina los peligros y abre una ventana de seis segundos con daño doble. Después se reconstruyen; en segunda fase son más débiles, mientras los pulsos aceleran y aparecen más marcas. Los anillos se esquivan al cruzarlos; las marcas fijan posiciones y avisan 0.9 s antes de impactar. Cada peligro golpea una sola vez y se elimina. Las compuertas y el anillo mecánico se animan.

Ambas arenas muestran todo el espacio para poder leer las franjas y los enlaces. Muerte y final detienen módulos y limpian peligros. Las escenas independientes permiten reintentar su propio jefe o volver al menú.

## Cómo probarlo en Godot

1. F5 abre el menú. Juega la Periferia, destruye sus repetidores y viaja de día. Tras vencer al Recaudador, pulsa **Viajar a Fundición**.
2. Lee la explicación de llegada: el reloj está detenido mientras aparece. Comprueba las mejoras y habitantes en la nueva colonia. Construye y observa las rejillas durante la noche.
3. Desbloquea la estación y derrota a Santa Caldera evitando las franjas y atacando durante la purga. Vuelve al menú antes de viajar y comprueba que **Continuar** carga el Barrio inundado.
4. Cruza los charcos andando y esquivando. En el Coro, rompe las tres antenas y aprovecha la apertura. La última victoria termina esta ruta disponible.

Para probar directamente una zona con F6: `levels/zones/foundry.tscn` o `flooded.tscn`. Para practicar jefes: `levels/expedition/caldera_arena.tscn` o `choir_arena.tscn`. Estas pruebas independientes empiezan con el equipo base.

## Validación

`tests/campaign_bosses_test.gd`: 69 comprobaciones de ataques, avisos sin daño, invulnerabilidad, aperturas, fases, límites de peligros, muerte, botones, esquema de campaña, guardados anteriores, protección entre zonas, viajes reales, persistencia de equipo y habitantes, reintento y Continuar desde el menú.

`tests/fresh_colony_simulation.gd -- --foundry` y `-- --flooded` prueban preparar las cuatro obras y resistir tres noches con apoyo automatizado, sin mejoras ni recursos gratuitos. Fundición: obras encargadas en 7.7 s, núcleo 300, final en 345.2 s. Barrio: 8.2 s, núcleo 300, final en 360.2 s. La prueba original mantiene 7.1 s y 240.5 s. Son simulaciones de sistemas; falta equilibrar dificultad con personas jugando.

`tests/run_all.gd` ejecuta 25 casos. Las capturas OpenGL de GTX 1070 se generan con:

```text
godot --path . --script res://tests/campaign_bosses_test.gd -- --capture
```

Quedan en `.godot/campaign/`, fuera de Git. Se usa un archivo de guardado de prueba separado. Los avisos conocidos del comprobador estático se explican en `MENU_Y_OPCIONES.md`; las pruebas de ejecución de campaña cierran sin fugas detectadas.

## Arte y especificaciones

Fondos propios generados con la herramienta integrada **imagegen**, sin imágenes de terceros como referencia. Integrados en `assets/background/foundry.png` y `flooded.png`, con importación sin filtrado, parallax y repetición alternada en espejo para evitar cortes. El fondo se oscurece para dar prioridad a personajes y señales. Los cuerpos de los jefes, rejillas, enlaces y vapor se dibujan y animan con GDScript; no dependen de un servicio externo al jugar. Partículas y destellos respetan las opciones.

Prompts empleados, conservados para variantes consistentes:

### Fundición

Original background art for CENIZA NEON 2D side-scrolling pixel-art survival game, FOUNDry district. Wide panoramic landscape 16:9, ideally 1536x864. Background environment ONLY: no people, no enemies, no UI, no writing, no logos, no train, no foreground floor or gameplay props. Orthographic side elevation, not isometric. Dense abandoned industrial foundry with giant blast-furnace silhouettes, layered catwalks, rusty chimneys, overhead cranes, steel conduits, distant orange molten channels and very sparse cyan powered windows. Nightfall smoke and drifting embers, detailed pixel clusters, restrained selective dark outline, square pixels, matte salvaged steel with bolts and pipes. Palette deep navy #0B1322 #182639, cold steel #304356 #8299A8, rust #E89E54, amber heat #FFCE75; no bright hostile magenta except tiny remote beacons. Atmospheric depth and a quiet low contrast empty upper third; leave the lower edge visually quiet for foreground gameplay added separately. Medium-wide environment establishing shot, flat readable factory silhouettes, no extreme perspective or tilted camera, no photorealism, no painterly brushwork, no oversaturated neon. The scene must still read at 640x360, sharp detailed pixels and gentle industrial haze.

### Barrio inundado

Original background art for CENIZA NEON 2D side-scrolling pixel-art survival game, FLOODED INDUSTRIAL QUARTER. Wide panoramic landscape 16:9 ideally 1536x864. Background environment ONLY: no characters, monsters, UI, writing, logos or foreground playable ground. Flat orthographic side elevation, not isometric. An abandoned industrial neighborhood partly submerged in dark blue water, broken elevated walkways, tall ruined communication towers with three distinctive circular relay dishes, leaning antenna silhouettes, waterlogged pipe systems, distant flooded warehouses. Restrained cyan reflections and a few pink-red relay beacons, mist just above the water, drizzle and tiny ripples, oxidized steel. Detailed crisp square pixel clusters, selective dark outlines, two or three shades per material. Palette #0B1322 #182639 #304356 #8299A8 with sparse #47DACB and #DD6482, very little amber. Melancholic blue-green twilight, strong atmospheric depth, low contrast quiet upper third, lower edge fades into dark watery mist for foreground gameplay added separately. Match an industrial cyberpunk pixel-art game at 640x360; calm readable masses, no painterly strokes, no photorealism, no smooth vector graphics, no saturated bloom, no dramatic perspective, no huge foreground objects.

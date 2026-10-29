# Caminar: archivos separados de LibreSprite

Abre cada `.ase` directamente en LibreSprite. Conservan las tres capas originales, el lienzo, la transparencia, el apoyo y la duración de los fotogramas. No contienen ataques ni otras acciones.

- `portador_caminar.ase`: Portador del mundo lateral.
- `portador_cenital_caminar.ase`: Portador de las arenas.
- `prefecto_caminar.ase`: Prefecto.
- `madre_caminar.ase`: Madre Cero.

Cada archivo tiene 32 fotogramas, repartidos en cuatro etiquetas de ocho: `walk_south`, `walk_east`, `walk_north` y `walk_west`. Selecciona la etiqueta y pulsa reproducir para revisar esa dirección. Mantienen los nombres y tiempos de la fuente aprobada.

Son copias independientes para editar; modificarlas no cambia automáticamente los atlas utilizados por el juego. Las fuentes completas siguen un nivel arriba. `python tools/art/extract_walk_sources.py` vuelve a extraer estas copias y sobrescribe los cuatro archivos separados; úsalo únicamente si quieres regenerarlos desde los originales.

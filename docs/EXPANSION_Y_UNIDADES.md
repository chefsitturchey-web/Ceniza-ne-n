# Colonias ampliadas y unidades de apoyo

> Registro anterior. Los módulos autónomos y relevos gratuitos se sustituyeron por trabajo y herramientas. Para jugar con las reglas actuales consulta [la revisión del GDD](REVISION_GDD_KINGDOM_SURVIVORS.md).

Bloque del 28 de octubre de 2026. Los tres distritos laterales pasan de 1920 a **3200 unidades de ancho**, con suelo físico, límites y cámara adaptados. Las antenas se desplazan a ±1440. El núcleo, la clínica, la estación, las cuatro defensas iniciales y los ajustes de velocidad/daño conservan sus posiciones o valores anteriores.

## Probar rápido

Abre **`levels/zones/expansion_playground.tscn` y pulsa F6**. Es un campo de práctica ambientado en Fundición, con las cuatro defensas principales listas, 260 de chatarra y 90 segundos de preparación. Presenta tres parejas de artillero y saboteador desde los 20 segundos. No carga ni escribe tu partida. Las cantidades de práctica pertenecen únicamente a esa escena.

Para jugar la campaña normal usa F5. Mantén E frente a un módulo vacío para pagar su despliegue de día. Su dron autónomo lo ensambla en seis segundos; los constructores siguen ocupándose de murallas y torretas. Recorre los extremos para encontrar cajas de suministros, que entregan 20 de chatarra una sola vez cada una. También pueden recuperarse de noche, asumiendo el riesgo del asedio.

## Cuatro estructuras, ocho emplazamientos

Cada tipo tiene un emplazamiento a cada lado del núcleo. Son opcionales: las cuatro defensas iniciales siguen costando las 90 unidades originales.

| Estructura | Distancia desde el núcleo | Coste | Energía | Función |
|---|---:|---:|---:|---|
| Cuartel | 450 | 50 | 1 | Despliega un fusilero que defiende su sector |
| Puesto médico | 820 | 45 | 1 | Despliega un dron sanitario |
| Generador | 1040 | 35 | Aporta 2 | Alimenta instalaciones de apoyo |
| Recicladora | 1230 | 40 | 0 | Produce 5 de chatarra cada 12 segundos operativos de día |

Todos tienen 180 de integridad. Mantén E de día para reparar uno dañado por 12 de chatarra; uno destruido requiere pagar de nuevo su coste de despliegue. Los generadores y recicladoras pueden reconstruirse aunque la red esté sobrecargada. Si un generador cae, las defensas principales conservan prioridad y el apoyo sin energía suspende sus acciones. El rótulo cercano indica falta de energía.

El frente enemigo se adapta a la expansión: aparece al menos 180 unidades más allá de la instalación activa o en montaje más exterior de su lado, respetando los límites del mapa. Sin módulos exteriores se mantiene la aparición original a ±650. Esto evita que nuevos enemigos nazcan dentro de una instalación recién conquistada.

## Aliados

**Fusilero:** 90 de vida, patrulla hasta 260 unidades alrededor del cuartel. Detecta enemigos en su sector, se coloca a distancia y dispara por 16 de daño cada 0.9 s, hasta 180 de alcance. Sus disparos no dañan al jugador.

**Dron sanitario:** 90 de vida, busca al jugador o a un aliado herido hasta 260 unidades de su puesto. Se acerca y recupera 8 de vida cada tres segundos con alcance de 80. No resucita al jugador.

Los enemigos pueden atacar a ambos. Un aliado caído deja de ser objetivo y su edificio envía un relevo tras 18 segundos con energía; destruir el edificio interrumpe el relevo hasta reconstruirlo. Cada edificio mantiene como máximo una unidad. Las unidades de apoyo pertenecen a sus puestos: en otro distrito se despliegan desde los edificios nuevos.

## Enemigos

**Artillero:** 90 de vida base, 28 de velocidad y 14 de daño. Se detiene para apuntar, muestra un aviso de 0.9 s y lanza un proyectil visible. Murallas, instalaciones y aliados interceptan la bala antes de que alcance algo situado detrás. La colisión recorre el segmento completo de movimiento y cada bala solo puede impactar una vez. La esquiva conserva su invulnerabilidad.

**Saboteador:** 100 de vida base y 52 de velocidad. Busca instalaciones operativas de su lado, se acerca y carga su herramienta antes de infligir 24 de daño. Sin instalaciones se comporta como enemigo de asedio normal. Su mochila, postura baja y sierra lo distinguen del artillero.

Se incorporan sustituyendo algunas máquinas de las noches 2 y 3; se conservan cantidades, lados y cadencias de las oleadas. En Fundición y Barrio inundado también aparecen en sus combinaciones avanzadas.

## Animación y presentación

Arte original dibujado por código, con la paleta industrial del proyecto: acero, óxido, cian aliado y rosa enemigo. No requiere descargar imágenes ni conectarse a un servicio al jugar.

- Fusilero y enemigos: piernas articuladas que responden al desplazamiento, brazos, armas, aviso de apuntado, retroceso, fogonazo y restos al caer.
- Sanitario: flotación, rotores, brazos laterales y haz de curación.
- Instalaciones: ensamblaje gradual y dron de montaje; rotor de generador, dientes móviles de recicladora, luces de estado, grietas, chispas y fragmentos al destruirse.
- Suelo y bruma abarcan el mapa entero; los módulos quedan detrás del personaje para conservar su lectura.

Los efectos usan las opciones existentes de partículas y destellos, y el audio compartido de disparo, mejora y destrucción. La producción musical final sigue pendiente.

## Guardado y edición

El guardado incorpora edificios, montaje, producción, suministros recogidos, vida/posición/cadencia de aliados y tiempo de relevo. Valida todos esos datos antes de aplicarlos. Un archivo anterior sin ampliación carga los emplazamientos vacíos, sin duplicar energía ni crear aliados. Los despliegues y suministros recogidos de día generan un checkpoint; se conserva además el guardado de amanecer. Al cambiar de distrito se reconstruyen las instalaciones locales.

Para ajustar costes, posiciones y tipos consulta `systems/expansion_system.gd` (`SPECS`). Las unidades están en `entities/workers/field_ally.gd`; sus gráficos en `components/field_unit_visual.gd`. Los dos enemigos tienen recursos en `data/enemies/` y comparten comportamiento especializado en `entities/enemies/raider.gd`. La práctica es un nodo controlador adicional y mantiene intacto el controlador principal de la colonia.

## Comprobaciones

`tests/expansion_test.gd`: **49 comprobaciones** de mapa físico, interacción mantenida, costes, energía, construcción, producción, daño/curación, relevos, sabotaje, balas con coberturas, animación, persistencia, datos inválidos, guardados anteriores y práctica aislada. Revisión gráfica con OpenGL en GTX 1070:

```text
godot --path . --script res://tests/expansion_test.gd -- --capture
```

Capturas locales en `.godot/expansion/`, fuera de los commits. La batería completa ejecuta **26 casos**. Las simulaciones actualizan también los proyectiles del artillero: sin apoyo la referencia pasa a 128.2 s (antes 128.6); con apoyo sigue en 240.5 s y núcleo 300. Desde una colonia nueva las tres zonas se superan con apoyo: núcleo 286, 258 y 272 respectivamente, sin desplegar módulos extra ni regalar recursos. Los tiempos de fin son 240.5, 345.2 y 360.2 s. La dificultad aún necesita pruebas con personas.

# CENIZA NEÓN

**Construye de día. Resiste de noche. Recupera la ciudad.**

Prototipo de supervivencia y defensa lateral en 2D, desarrollado con **Godot y GDScript**. En unas ruinas industriales cyberpunk, diriges a un portador de una llave neuronal capaz de reactivar infraestructura y proteger a los últimos supervivientes de una red de máquinas hostiles.

La colonia es tu defensa principal. Tu personaje combate, repara la situación en el frente más presionado y activa sobrecargas eléctricas para cambiar el rumbo del asedio.

> **Estado: prototipo jugable en desarrollo.** Partida de tres noches; configuración base de aproximadamente ocho minutos. Este worktree conserva el ajuste de pruebas con días de 10 segundos (unos cuatro minutos). Errante, corredor y constructor tienen animaciones; el resto del arte es provisional. Guardado automático al comenzar cada día. Todavía no hay sonido.

[Cómo jugar](#cómo-probarlo) · [Controles](#controles) · [Estado del proyecto](#estado-del-proyecto) · [Reportar un problema](https://github.com/chefsitturchey-web/Ceniza-ne-n/issues)

## Qué puedes probar

- Movimiento lateral, combate cuerpo a cuerpo y esquiva con resistencia.
- Construcción y reparación de murallas y torretas en posiciones predeterminadas.
- Reclutamiento de hasta cuatro habitantes: constructores y recuperadores con tareas automáticas.
- Producción de chatarra, capacidad energética y sobrecarga independiente por frente.
- Un dron de apoyo y dos enemigos con comportamientos y velocidades diferentes.
- Ciclo de preparación, aviso y asedio, con ataques desde ambos lados.
- Reaparición del personaje, pausa, victoria, derrota y reinicio.

## Cómo probarlo

### Requisitos

| Componente | Configuración utilizada |
|---|---|
| Motor | Godot **4.7.2**, edición estándar; no requiere .NET |
| Plataforma de desarrollo y pruebas | Windows |
| Renderizador | Compatibility |
| Controles | Teclado; soporte de mando implementado |
| Dependencias adicionales | Ninguna |

La versión indicada es la utilizada para desarrollar y comprobar este prototipo, no una garantía de compatibilidad con todas las versiones de Godot 4. Otros sistemas operativos y modelos de mando todavía necesitan pruebas. No se han establecido requisitos mínimos de hardware.

### 1. Obtén el proyecto

Con Git:

```bash
git clone https://github.com/chefsitturchey-web/Ceniza-ne-n.git
cd Ceniza-ne-n
```

También puedes pulsar **Code → Download ZIP** en GitHub y extraer el archivo en una carpeta local. No necesitas Git si utilizas esta opción.

### 2. Ábrelo en Godot

1. Abre el administrador de proyectos de Godot.
2. Pulsa **Importar** y selecciona `project.godot` dentro de la carpeta descargada.
3. Abre el proyecto y espera a que termine la importación inicial.
4. Presiona **F5** para ejecutar el juego.

El proyecto se prueba desde el editor; este repositorio no incluye un ejecutable de Windows. No necesitas instalar plugins ni descargar recursos adicionales.

### 3. Sobrevive a tu primera noche

1. **Construye ambos frentes.** Empiezas con 90 de chatarra, un constructor y un recuperador. Acércate a los marcos de construcción y mantén **E**: cada muralla cuesta 20 y cada torreta 25. Las cuatro obras suman 90.
2. **Deja trabajar a la colonia.** Encargar una obra no la completa inmediatamente. El constructor se desplaza hasta ella; el recuperador sale de día y deposita chatarra automáticamente.
3. **Amplía el equipo.** Con los recursos producidos, vuelve al núcleo central y mantén **E** para reclutar. Cada nuevo habitante cuesta 15, hasta un máximo de cuatro. Si estás herido, la interacción primero te cura; ambas acciones están disponibles durante el día.
4. **Responde al asedio.** Al anochecer, revisa los indicadores de amenazas de ambos lados. Ataca con **J**, esquiva con **Espacio** y utiliza **Q** para sobrecargar el frente donde te encuentras.
5. **Recupera las defensas.** Encarga reparaciones en las estructuras dañadas por ocho de chatarra. Los constructores esperan si hay enemigos cerca: despejar la zona también es parte de tu trabajo.

La configuración base tiene **90 segundos de día, 10 de aviso y 60 de noche**. El distrito actual conserva tu ajuste de **10 segundos de día**: en `levels/main.tscn`, selecciona `Cycle` y asigna `data/cycles/standard.tres` a `config` si quieres el tiempo completo de preparación. La noche se prolonga si quedan enemigos. Sobrevive a las tres noches para ganar; si destruyen el núcleo, pierdes. Al morir, el personaje reaparece después de cuatro segundos mientras la colonia sigue defendiéndose.

**Consejo:** la sobrecarga dura seis segundos y después necesita dieciocho de enfriamiento. Cada frente tiene su propio temporizador: úsala cuando la defensa esté bajo presión.

## Controles

| Acción | Teclado | Mando Xbox |
|---|---|---|
| Movimiento | A / D o flechas izquierda / derecha | Stick izquierdo o cruceta |
| Ataque, repetible al mantener | J | X |
| Esquiva | Espacio | A |
| Construir, reparar, reclutar o curar | Mantener E | Mantener Y |
| Sobrecarga del frente actual | Q | LB |
| Pausar / continuar | Esc | Start |
| Nueva partida después de ganar o perder | R | Select / Back |

En PlayStation, las equivalencias principales son **Cuadrado** para atacar, **Cruz** para esquivar, **Triángulo** para interactuar y **L1** para sobrecargar. El HUD utiliza las etiquetas de Xbox.

Para detener la ejecución desde el editor, utiliza **F8**.

Al volver a ejecutar con **F5**, continúas desde el inicio del último día guardado en `user://partida.json`. Se conservan recursos, habitantes, obras pendientes, defensas y vida. Ganar, perder o reiniciar elimina ese guardado. Un archivo corrupto o de versión desconocida inicia una partida nueva.

## Estado del proyecto

Esta versión valida el ciclo de construcción y defensa. El alcance completo del documento de diseño todavía está en desarrollo.

| Disponible | Pendiente |
|---|---|
| Un escenario provisional con dos frentes | Distritos, expediciones y campaña |
| Tres asedios y dos tipos de enemigo | Jefes y más variedad de amenazas |
| Combate manual, esquiva y dron | Equipo, evoluciones y progresión |
| Economía y trabajadores simplificados | Infraestructura y profesiones ampliadas |
| Formas y efectos provisionales | Sprites, animaciones, música y sonido |
| Reinicio de sesión y guardado al amanecer | Guardado durante el asedio |

**Limitaciones actuales:** la chatarra se almacena en una bolsa común, la capacidad energética es fija, los trabajadores no reciben daño y las torretas no son objetivos de los enemigos. Al cerrar se pierde lo realizado después del último amanecer; perder elimina la partida. La dificultad y la legibilidad visual requieren pruebas con jugadores.

## Documentación y estructura

- [Guía de la versión actual](INICIO.md): reglas y detalles para probar el prototipo.
- [Dirección de arte y prompts](docs/GUIA_ARTE.md): paleta, dimensiones y referencias para producir recursos consistentes.
- [Documento de diseño — GDD](CENIZA_NEON_GDD.docx): visión y alcance previsto del juego; no es una lista de funciones ya implementadas.
- [Registro de recursos](docs/ASSET_SOURCES.csv): procedencia y condiciones de uso de los futuros assets.
- [Arquitectura y señales](docs/ARQUITECTURA.md): responsabilidades, configuración y pruebas.

```text
core/           Controles y constantes de capas, grupos y reglas compartidas
components/     Vida, hitbox, hurtbox e interfaz visual reutilizables
entities/       Jugador, enemigos, trabajadores, estructuras y núcleo
systems/        Ciclo, economía, obras, colonia, asedio, defensas y sesión
ui/             HUD como escena receptora de señales y su presentador
data/           Definiciones Resource y configuraciones .tres
levels/         Distrito principal: composición de nodos y conexiones
assets/         PNG originales y sus ajustes de importación
tests/          Pruebas de reglas y simulaciones de sesión
docs/           Dirección de arte y registro de recursos
project.godot   Configuración y punto de entrada del proyecto
```

## Pruebas automatizadas

Desde la carpeta del proyecto, con el ejecutable de Godot disponible como `godot`:

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/run_all.gd
```

`run_all.gd` ejecuta combate, asedio, animaciones, vida, carga de los 11 Resources, oleadas, integración visual, compilación y ambas simulaciones. Sale con código distinto de cero ante un fallo. Para ejecutar pruebas individuales:

```bash
godot --headless --path . --script res://tests/combat_smoke.gd
godot --headless --path . --script res://tests/siege_smoke.gd
godot --headless --path . --script res://tests/errante_animation_smoke.gd
godot --headless --path . --script res://tests/session_simulation.gd
godot --headless --path . --script res://tests/session_simulation.gd -- --assist
```

En Windows puedes sustituir `godot` por la ruta de tu ejecutable de consola. En PowerShell, una ruta entre comillas se ejecuta anteponiendo `&`.

Las pruebas cubren alcance, daño, economía, obras, energía, esquiva y condiciones de finalización. Las simulaciones parten de defensas construidas: sin apoyo se espera una derrota; con apoyo automatizado, una victoria. No sustituyen la prueba visual, la comprobación del mando ni el ajuste de dificultad con jugadores.

## Añadir contenido con Resources

**Enemigo:** duplica una escena de `entities/enemies/`, conserva su raíz con `SiegeEnemy` (o un script que lo extienda) y configura `AnimatedSprite2D`. Usa `reposo`, `ataque`, `daño`, `destruccion` y la animación de avance indicada por `move_animation`. Crea un `EnemyData` en `data/enemies/`, asigna la escena, identidad, estadísticas y recompensa. Añádelo al array `enemies` de una oleada en `data/waves/`, con una entrada correspondiente en `sides` (-1 izquierda, +1 derecha). El director no necesita cambios de código. El número de elementos determina la cantidad; puedes repetir referencias.

**Estructura:** duplica un `StructureData` de `data/structures/`. Ajusta nombre, costo, vida, reparación, energía, posición y ataque. Asigna una escena con raíz `ConstructionSite` (puedes reutilizar `entities/structures/site.tscn` o extenderla para otro aspecto). Añade el Resource a `Construction.blueprints` en `levels/main.tscn`: aparecerá en ambos lados, a la distancia `offset`. `blocks_enemies` define si bloquea; `damage` mayor que cero habilita disparos. Las reglas de obra, vida, reparación y energía son compartidas.

Para modificar trabajadores, edita sus `WorkerData`; para tiempos y premios, el `CycleConfig` asignado a `Cycle`. No cambies los Resources durante una partida: cada entidad mantiene su estado por separado. Al mover scripts, mueve también sus `.gd.uid` y reimporta.

## Comentarios y problemas

Puedes compartir tus resultados o abrir un [issue](https://github.com/chefsitturchey-web/Ceniza-ne-n/issues). Para facilitar la revisión, incluye:

- Qué esperabas y qué ocurrió, con pasos para reproducirlo.
- Versión de Godot, sistema operativo y teclado o modelo de mando utilizado.
- Noche y situación en la que apareció el problema.
- Captura, vídeo breve o mensaje de error, si corresponde.

También nos interesa saber si se entiende cómo construir, si puedes atender ambos frentes y en qué momento la dificultad deja de sentirse justa.

---

Creado por **Carlos Alberto Llano Flores — Turchey**. Desarrollado con Godot y GDScript.

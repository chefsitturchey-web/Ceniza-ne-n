# Revisión del GDD y corrección de las mecánicas

Se leyó completo `CENIZA_NEON_GDD.docx`, versión 1.0 de Carlos Alberto Llano Flores, incluidas sus 31 secciones y el anexo. El DOCX original se conserva. Esta entrega corrige sistemas anteriores; no declara terminado todo el alcance de lanzamiento.

## Diagnóstico

El documento asigna 60 % a Kingdom, 25 % a acción resistente y 15 % a Vampire Survivors. Los edificios autónomos, soldados generados gratuitamente y compras cada seis bajas no representaban bien ese diseño. Las secciones 3, 5, 8, 9, 13 y 16 piden inversión territorial, población, herramientas, trabajo, experiencia y elecciones de equipo.

## Referencias investigadas

Kingdom se presenta como microestrategia lateral de inversión, reclutamiento, exploración y defensa nocturna. [Sitio oficial](https://kingdomthegame.com/), [Raw Fury](https://rawfury.com/games/kingdom-two-crowns/). Se contrastaron también las reglas de [constructores](https://kingdomthegame.fandom.com/wiki/Builder), [murallas](https://kingdomthegame.fandom.com/wiki/Wall) y [herramientas](https://kingdomthegame.fandom.com/wiki/Tools_and_weapons): una herramienta da profesión, las obras necesitan personas y la muralla exterior establece el frente. Se adapta esa relación a infraestructura industrial, con recursos y gráficos propios.

**La cantidad de portales no es universal.** En Europa/Shogun, la campaña base de Two Crowns tiene 0/1/2/3/3 portales pequeños por lado, además de dos entradas terminales: 2/4/6/8/8 en total. Otras campañas cambian la distribución. [Distribución por isla](https://kingdomthegame.fandom.com/wiki/Islands_in_Two_Crowns). Nuestra adaptación usa las tres primeras escalas sin sustituir los dos repetidores exigidos por el GDD:

| Distrito disponible | Repetidores terminales | Brechas intermedias | Entradas totales |
|---|---:|---:|---:|
| Periferia | 2 | 0 | 2 |
| Fundición | 2 | 2 | 4 |
| Barrio inundado | 2 | 4 | 6 |

Vampire Survivors combina gemas recogibles, pausa de subida de nivel y tres o cuatro alternativas de equipo. Sus cofres pueden transformar armas que cumplen condiciones. [Subida de nivel](https://vampire-survivors.fandom.com/wiki/Level_up), [armas](https://vampire-survivors.fandom.com/wiki/Weapons), [evoluciones](https://vampire.survivors.wiki/w/Evolution), [poncle](https://poncle.games/coop-faq). Aquí se mantiene el límite propio del documento: dos módulos, cuatro pasivas equipadas y equipo de nivel cinco, dentro de una campaña persistente.

## Construcción y habitantes

- Pagar encarga una obra: ya no se termina sola por esperar. Los constructores caminan, trabajan, comparten obras exteriores hasta dos por tarea, priorizan trabajos centrales seguros y se retiran de zonas exteriores amenazadas o sin protección al anochecer. Los recuperadores regresan ante peligro.
- Hay tres emplazamientos adicionales de muralla por lado. Cada muralla tiene tres niveles de integridad: 240/480/720 con el recurso actual. Mejorar cuesta otro pago y trabajo; la muralla exterior terminada amplía el perímetro. Cimientos, fichas de coste, andamios y soldadura comunican el estado.
- Los campamentos venden contratación por cinco de chatarra. El superviviente empieza sin profesión y toma herramientas pagadas en los puestos del taller izquierdo. Persona y herramienta son inversiones separadas.
- Hay herramientas de constructor, recuperador, tirador, guardián, técnico y médico. Cuarteles alojan hasta tres tiradores/guardianes; el médico ocupa un puesto médico y el técnico un generador. Si una profesión no tiene plaza, las personas pueden tomar otra herramienta disponible.
- Los guardianes reducen daño con su escudo, los médicos curan y los técnicos reparan su infraestructura. La escolta se acerca al perímetro y combate amenazas próximas. F alterna avance contra las entradas del lado elegido y retirada.
- Una unidad de apoyo derrotada queda desarmada y vuelve a ser superviviente. Hace falta otra herramienta para rearmarla: no aparece un reemplazo gratuito. El refugio permite ampliar capacidad desde ocho hasta veinte habitantes; al máximo permite devolver un trabajador adicional a estado sin profesión para reasignarlo, conservando los dos trabajadores iniciales.
- Las instalaciones de apoyo siguen necesitando energía. Las defensas centrales tienen prioridad si cae un generador. Mantener E frente a una torreta terminada permite apagarla para liberar capacidad y reactivarla después. Hay que soltar el botón entre acciones. Las construcciones sin consumo pueden reconstruirse aunque la red esté sobrecargada.

Las brechas abiertas impiden construir detrás de ellas. Las oleadas salen de la entrada abierta más cercana; un frente completamente cerrado deja de generar su oleada ordinaria. Una brecha intermedia destruida anuncia un contraataque con tres segundos de margen.

Para viajar se necesita sobrevivir una noche, mantener ambas murallas centrales y un generador, cerrar las entradas y disponer del tren de día. Así no se omite toda la colonia corriendo directamente al jefe.

La escena principal usa `data/cycles/kingdom.tres`: 180 s de día, 20 de aviso y 90 de noche. El GDD propone 12 minutos ajustables; este bloque usa **4 min 50 s** como punto de prueba. `district.tres` y `standard.tres` conservan sus valores anteriores. Se mantienen velocidad 220 y daño 50 del personaje.

## Experiencia y equipo

Los enemigos dejan datos físicos, aunque los mate una defensa. Recogerlos llena una barra. Cada nivel detiene el tiempo y presenta tres opciones distintas; las elecciones se resuelven sucesivamente si se ganan varios niveles. Curva actual: `8 + 3 × (nivel − 1)`, máximo nivel 30.

Las opciones incluyen desbloquear/mejorar módulos, pasivas e implantes existentes. Hay seis pasivas para elegir cuatro equipadas: óptica, batería, rodamiento, atracción, impacto y recuperación. Cada una alcanza cinco niveles. La clínica permite consultar y configurar lo obtenido; las mejoras nuevas se eligen al subir de nivel.

Las élites dejan cofres físicos con evoluciones válidas, mejoras normales o la posibilidad de guardar un núcleo. La receta sigue el GDD: arma cinco, pasiva compatible equipada y núcleo del cofre. Retirar luego la pasiva no elimina una evolución adquirida. Los jefes dan experiencia y un núcleo garantizados. Equipo, niveles y elecciones pendientes continúan entre distritos; el botín físico permanece en su escenario.

Morir deja una señal con la experiencia restante hacia el próximo nivel y conserva lo adquirido. Volver a ella permite recuperarla; otra muerte la sustituye. Perder el núcleo conserva el guardado diario, también en la primera colonia.

## Caldera, arte y legibilidad

Santa Caldera conserva calor, salvas y purga vulnerable. Ahora se desplaza, gira y realiza una arremetida anunciada —dos en segunda fase—. La arena es octogonal, con diagonales físicas, metal fundido, maquinaria animada, vapor y coberturas. El cuerpo nuevo tiene silueta de horno articulado.

Cuartel, puesto médico, generador y recicladora usan un atlas nuevo con tejados, cobre, puertas, cables, instrumentos y desgaste. Se revela por etapas durante el trabajo. La lógica determina daño y funcionamiento; la imagen no sustituye el sistema.

La cámara lateral usa zoom 1.25 y deja espacio delante de la pasarela. Un canal refleja escenario, edificios y personajes con ondas suaves. El texto pasa de Micro5 a diez píxeles a Silkscreen de doce; pausa, clínica y selección se reorganizan para separar textos y evitar recortes. La barra de experiencia se oculta en menús y expediciones.

## Cómo probar

1. F5 → Nueva partida. Mantén E en los cimientos y observa a los constructores desplazarse.
2. Explora suministros, encarga un generador y cuartel. Recluta en un campamento y paga un fusil en el taller izquierdo: el superviviente debe caminar a la herramienta y ocupar una plaza.
3. Construye y mejora una muralla exterior. F / cruceta arriba ordena avance o retirada de la escolta por el lado donde estás.
4. Recoge datos, elige cartas y abre cofres. Consulta recetas y cambia pasivas en la clínica.
5. Cierra las brechas, estabiliza la colonia y toma el tren de día.
6. Práctica sin guardado: F6 en `levels/zones/expansion_playground.tscn`. Caldera directamente: F6 en `levels/expedition/caldera_arena.tscn`.

## Validación

`tests/gdd_foundations_test.gd`: **67 comprobaciones** de trabajo y recorrido, retirada, contratación, herramientas, escuadras, guardianes, técnicos, sanitarios, niveles de muralla, energía con desactivación, perímetros, entradas, contraataques, experiencia, elecciones, cofres, evolución, cuatro ranuras, cambio de catalizador, muerte, guardado, movilidad/geometría y límites de interfaz. `expansion_test.gd` conserva el acceso anterior como alias de esta suite actualizada.

La batería completa mantiene 26 casos, incluidas simulaciones que recogen datos y eligen mejoras automáticamente. Las capturas OpenGL se producen con `godot --path . --script res://tests/gdd_foundations_test.gd -- --capture` y quedan en `.godot/gdd/`, fuera de Git. Se usan archivos y perfil de usuario de prueba. Falta equilibrio humano y medir la carga objetivo de 100 enemigos y 40 habitantes.

## Auditoría del resto del documento

| Secciones | Implementado o corregido | Pendiente |
|---|---|---|
| 1–6: concepto, referencias, ciclo, mundo, sobrecarga | Base lateral, inversión, frentes, expediciones y sobrecarga | Beneficios fijos de distritos estabilizados, composición de mapas por semilla |
| 7: economía | Chatarra, capacidad energética, experiencia y núcleos | Separar recursos transportados y almacén protegido |
| 8–9: población y edificios | Profesiones con herramientas, refugio, trabajo, murallas y apoyo | Almacén separado, barrera eléctrica, torre tripulada dedicada y variantes de torreta |
| 10–12: personaje, clínica, muerte | Combate, esquiva, configuración, señal y restauración diaria | Habilidad de arma, curación con cargas, clínica que repueble enemigos en expedición |
| 13–16: progresión, perfiles, NPCs, equipo | Niveles, elecciones, módulos, pasivas y cofres | Talentos cada cinco niveles, tres perfiles, NPC narrativos y completar los ocho equipos/evoluciones |
| 17–19: enemigos y jefes | Siete arquetipos, tres distritos y tres jefes | Dron cazador, Portador, Reparador, Ciudadela, Prefecto y MADRE CERO |
| 20–24: duración, tecnología, arte y rendimiento | Sistemas separados y contenido probado | Medición de duración, generación por semilla y presupuesto de rendimiento |
| 25–31: producción y anexos | Campaña individual y validación local | Narrativa, música final, localización, remapeo completo, pruebas externas y preparación de lanzamiento |

## Arte y especificaciones de reproducción

Habilidad utilizada: **imagegen**, generación integrada con transparencia, sin imágenes de terceros como referencia. Los originales se conservan y se copiaron al proyecto. El atlas se usa mediante regiones de textura en Godot.

- `assets/expedition/boss/caldera_v2.png`: prompt de producción para un único horno-cangrejo cenital articulado, centrado y completo sobre transparencia, aproximadamente 110×120 píxeles lógicos, contorno navy, cobre oxidado, núcleo hexagonal ámbar, remaches, manómetros, mangueras corrugadas, radiadores, chimeneas, cuatro patas hidráulicas y dos pinzas. Silueta ancha con espacios vacíos, lectura a tamaño pequeño, sin suelo, UI, texto ni perspectiva isométrica.
- `assets/structures/industrial_atlas_v2.png`: prompt de atlas transparente de cuatro edificios en cuadrícula 2×2, celdas iguales, siluetas completas y separadas, elevación lateral plana. Arriba: cuartel con tejado, antena, armas y sacos; clínica de tejado redondeado, cruz cian y puerta acristalada. Abajo: generador con cilindros, turbina y bobinas; recicladora con cinta, grúa, engranaje y luz de fragua. Píxeles definidos, metal desgastado y dos o tres tonos por material.

Paleta compartida para variantes: `#0B1322`, `#182639`, `#304356`, `#8299A8`, `#704C43`, `#E89E54`, `#FFCE75`, `#47DACB`; rosa `#DD6482` reservado a amenaza. Evitar texto, fondos opacos, recortes, suavizado borroso y objetos cruzando celdas del atlas.

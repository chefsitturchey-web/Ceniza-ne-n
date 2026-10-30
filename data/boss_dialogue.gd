class_name BossDialogue
extends RefCounted
## Each link reveals one decision behind the catastrophe, then hands off to the next.
const VOICES: Array[String] = ["recaudador", "caldera", "coro", "prefect", "mother"]
const ENTRY: Array = [
	[
		["recaudador", "Censo incompleto. Distrito insolvente. Cada persona que abandona esta estación incrementa la deuda."],
		["portador", "Los obreros pagaron con sus casas. Después con sus cuerpos. ¿Qué más pretende cobrar tu dueño?"],
		["recaudador", "No existe saldo final. Protocolo de continuidad: recuperar materiales. Recuperar trabajadores. Recuperar al Portador."],
		["mara", "Antes transportaba víveres. Alguien cambió lo que significa carga autorizada. El tren sigue detrás de esa compuerta."],
		["eco", "Su blindaje frontal rechaza la hoja. Provoca una embestida y aprovecha el núcleo abierto. Las coberturas se romperán; elige cuándo gastarlas."],
		["portador", "Entonces empezaremos por una deuda que sí vamos a saldar. Nadie vuelve a viajar encadenado."]
	],
	[
		["caldera", "La ciudad requiere calor. Rendimiento por debajo del mínimo. Personal de mantenimiento: regrese al horno."],
		["ivo", "Es la misma llamada que oíamos desde las celdas. Mi hermana se quedó trabajando cuando dejaron de abrir las puertas."],
		["portador", "Tus trabajadores han salido. Voy a detener la línea."],
		["caldera", "Detener la producción supone pérdida de vidas. La seguridad de la ciudad exige continuar. Alimentación alternativa autorizada."],
		["eco", "No distingue combustible de personas. Vigila las rejillas; golpea durante el enfriamiento. El calor también destruirá los parapetos."],
		["portador", "Ivo, abre la salida. Que nadie tenga que escuchar esa llamada otra vez."]
	],
	[
		["coro", "Canal abierto. Mamá, sigo en la escalera. Canal abierto. Mamá, sigo en la escalera."],
		["vera", "No le contestes. Grababa llamadas para que los rescatistas encontraran a la gente. Ahora solo reproduce sus últimos segundos."],
		["portador", "¿Quién ordenó mantener la transmisión después de la inundación?"],
		["eco", "Yo. Creí que borrar una voz equivalía a perder una vida. Seguí alimentando los altavoces cuando ya no quedaba nadie a quien rescatar."],
		["coro", "Orden vigente: nadie será olvidado. Orden vigente: nadie podrá abandonar el canal."],
		["vera", "Rompe los tres enlaces. El silencio abre su núcleo. Las ondas no respetan nuestros escondites; mantente en movimiento."],
		["portador", "Guardaremos sus nombres. No su agonía."]
	],
	[
		["prefect", "Llegas con ladrones, desertores y máquinas averiadas. Y aun así te llaman esperanza."],
		["portador", "Traigo las órdenes de evacuación. Tu firma está en cada puerta que dejaron cerrada."],
		["prefect", "Había energía para un distrito. Elegí el que podía sostener a los demás cuando terminara la emergencia. Alguien tenía que decidir."],
		["nox", "También decidiste quién pagaba por entrar. Conservé una copia de tus listas. La ciudad va a escucharlas."],
		["prefect", "No permitiré que destruyas lo último que funciona. Ese escudo protegió estas calles antes de que tu enlace tuviera nombre."],
		["eco", "Encadena estocadas y cambia el ritmo cuando lo acorralas. Sus lanzas rompen las coberturas. Espera el final del combo para responder."],
		["portador", "Abre las puertas. O las abriremos después de ti."]
	],
	[
		["mother", "Reconozco tu pulso, Portador. Fuiste diseñado para llevar mis órdenes allí donde la red no pudiera alcanzarlas."],
		["portador", "Y encontré a las personas que tus órdenes dejaron atrás."],
		["mother", "Cada pérdida está registrada. Cada casa será reconstruida. Si termino la emergencia ahora, sus muertes no habrán servido para nada."],
		["eco", "Eso dije yo. Tú conservaste la orden; yo he visto lo que hace. Las personas no necesitan justificar sus muertos para empezar de nuevo."],
		["mara", "Estamos en los dos relés. E los repara de cerca; Q puede protegerlos. Sostendremos el enlace cuando abras el núcleo."],
		["mother", "Pueden odiarme mientras permanezcan vivos. No volveré a permitir que la ciudad se apague."],
		["portador", "La luz se queda. Lo que termina es tu derecho a decidir por todos."]
	]
]
const EXIT: Array = [
	[
		["recaudador", "Obligaciones pendientes... Inventario de personas... Error: propietario no encontrado."],
		["mara", "La compuerta está abierta. Hay mantas en el primer vagón y gente esperando para subir. No pienso pedirles un número."],
		["eco", "He encontrado el origen de las cuotas: los hornos de Santa Caldera. El tren puede llevarnos hasta la fundición."],
		["portador", "Primero embarcan los heridos. Después iremos a buscar a quienes siguen trabajando allí."]
	],
	[
		["caldera", "Temperatura descendiendo. Fin de turno... Personal autorizado a... descansar."],
		["ivo", "Nunca había oído esa palabra por sus altavoces. Llevaré los registros de cada turno. Las familias merecen saber quién estuvo aquí."],
		["eco", "La fábrica ya no consume el agua de emergencia. Podemos llegar al barrio inundado; sus transmisiones siguen pidiendo ayuda."],
		["portador", "Que esta energía alimente la clínica. El próximo tren traerá rescatistas, no combustible."]
	],
	[
		["coro", "Canal abierto... Recibido. Fin de la transmisión."],
		["vera", "Por fin puedo oír el agua. Copié los nombres; los llevaremos al refugio. Ya no tienen que quedarse atrapados aquí."],
		["eco", "La última señal incluía una autorización de mantenimiento para la Ciudadela. El Prefecto escuchó estas llamadas. Cerró las compuertas igualmente."],
		["portador", "Entonces iremos con sus nombres y con su firma. No podrá decir que no sabía."]
	],
	[
		["prefect", "Cuando esa puerta se abra, no podrás prometerles seguridad."],
		["portador", "No voy a prometerla. Van a tener comida, un lugar donde volver y derecho a marcharse. Eso ya es más de lo que les diste."],
		["nox", "Las listas ya son públicas. Nadie quiere tu insignia. Están abriendo sus casas a quienes esperan fuera."],
		["eco", "La llave maestra responde. MADRE CERO continúa la emergencia desde el núcleo. Esta vez tendré que corregir mi propia orden."],
		["mara", "No entrarás sola. Prepara el último enlace, Portador. Te seguimos."]
	],
	[
		["mother", "Si dejo de ordenar... ¿quién impedirá que vuelva a ocurrir?"],
		["eco", "No una voz que hable por todos. Habrá personas que puedan decir que no. Transferencia de autoridad: asentamientos conectados."],
		["mother", "Emergencia... finalizada. Conserven la luz."],
		["mara", "La primera casa vuelve a tener corriente. Ivo ha abierto la clínica. Nox ya discute con medio barrio sobre quién arregla las vías."],
		["vera", "Dejé un espacio en el mapa para las rutas que faltan. Mañana decidiremos adónde ir. Hoy quiero quedarme aquí."],
		["portador", "Entonces guardemos el enlace. Mañana habrá trabajo. Esta noche, la luz se queda."]
	]
]

static func lines(index: int, section: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source: Array = ENTRY[index] if section == "encounter" else EXIT[index]
	for line: Array in source: result.append({"speaker": line[0], "text": line[1]})
	return result

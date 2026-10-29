class_name VisualStory
extends RefCounted
## Guion de presentación: conserva el lore y lo reparte en intervenciones legibles.
const SECTIONS: Array[String] = ["opening", "rescue", "relay", "convoy", "encounter", "ending"]
const TITLES: Dictionary = {"opening": "Llegada", "rescue": "Supervivientes", "relay": "Una red propia", "convoy": "El regreso", "encounter": "Ante el enlace", "ending": "Después del combate"}
const ACTORS: Dictionary = {"MARA": "mara", "IVO": "ivo", "VERA": "vera", "NOX": "nox", "ECO": "eco", "PORTADOR": "portador", "EL PREFECTO": "prefect", "MADRE CERO": "mother"}
const QUESTIONS: Array[String] = ["¿Por dónde empezamos?", "¿Todavía podemos sacar a esas personas?", "¿Quién sigue hablando desde las antenas?", "¿Quién decidió que los demás se quedaran fuera?", "¿Podemos terminar esto sin repetir el mismo error?"]
const ANSWERS: Array[String] = ["Entonces levantaremos algo que no puedan cobrarnos.", "Abriremos una salida. Nadie se queda en esa línea de montaje.", "Las escucharemos. Y después dejaremos que descansen.", "Esta vez abriremos las puertas desde dentro.", "Mantendremos el enlace. La decisión será de quienes viven aquí."]

static func actor_name(id: String) -> String:
	for name: String in ACTORS:
		if ACTORS[name] == id: return name
	return "CENIZA NEÓN"

static func valid_key(key: String) -> bool:
	var parts: PackedStringArray = key.split(":")
	return parts.size() == 2 and parts[0].length() == 1 and parts[0].is_valid_int() and int(parts[0]) >= 0 and int(parts[0]) < 5 and parts[1] in SECTIONS

static func chunks(text: String) -> Array[String]:
	var result: Array[String] = []
	var current: String = ""
	for sentence: String in text.split(". "):
		var words: PackedStringArray = sentence.strip_edges().split(" ")
		for word: String in words:
			if current.length() + word.length() > 155 and not current.is_empty():
				result.append(current.strip_edges())
				current = ""
			current += word + " "
		current = current.strip_edges()
		if not current.ends_with(".") and not current.ends_with("?") and not current.ends_with("!"): current += "."
		if current.length() > 95:
			result.append(current)
			current = ""
		else: current += " "
	if not current.strip_edges().is_empty(): result.append(current.strip_edges())
	return result

static func append_text(lines: Array[Dictionary], speaker: String, text: String) -> void:
	for paragraph: String in chunks(text): lines.append({"speaker": speaker, "text": paragraph})

static func scene(index: int, section: String) -> Dictionary:
	var chapter: Dictionary = CampaignStory.chapter(index)
	var lines: Array[Dictionary] = []
	var companion: String = ACTORS.get(chapter.voice, "eco")
	if section == "encounter":
		lines.append({"speaker": "portador", "text": ["El Recaudador está cortando el paso al tren.", "El suelo sigue ardiendo. Tendremos que buscar el momento de acercarnos.", "Son tres enlaces. Mientras sigan vivos, no podremos alcanzar el núcleo.", "No vengo por tu insignia. Vengo a abrir la ciudad.", "Mara, mantén los relés. ECO, no cierres el enlace."][index]})
		lines.append({"speaker": "prefect" if index == 3 else ("mother" if index == 4 else "eco"), "text": ["Su escudo protege el frente. Deja que embista contra una cobertura y ataca cuando abra el núcleo.", "Las rejillas anuncian el calor. Durante la purga de enfriamiento podrás golpearla.", "Corta las antenas y esquiva los pulsos. El silencio abrirá una ventana.", "Fuera de estas murallas no hay nada que pueda durar. Yo conservé lo único que importaba.", "La emergencia no ha terminado. Apagarme significa abandonar a todos."][index]})
		if index == 4: lines.append({"speaker": "mara", "text": "Necesitamos dos relés activos. E los repara si estás cerca; Q puede protegerlos. Aguantaremos hasta que se abra."})
		lines.append({"speaker": "portador", "text": ANSWERS[index]})
	else:
		var text: String = chapter[section]
		if section == "opening":
			lines.append({"speaker": "portador", "text": QUESTIONS[index]})
		elif section in ["rescue", "relay", "convoy"]:
			lines.append({"speaker": "portador", "text": {"rescue": "Estamos aquí. Dime qué ocurrió.", "relay": "El relé vuelve a responder. ¿Qué cambia para la colonia?", "convoy": "El transporte ha llegado. ¿Qué hemos recuperado?"}[section]})
		else: companion = "narrator"
		var parser: RegEx = RegEx.new()
		parser.compile("(EL PREFECTO|MADRE CERO|PORTADOR|MARA|IVO|VERA|NOX|ECO):\\s*")
		var matches: Array[RegExMatch] = parser.search_all(text)
		if matches.is_empty(): append_text(lines, companion, text)
		else:
			if matches[0].get_start() > 0: append_text(lines, companion, text.substr(0, matches[0].get_start()))
			for offset: int in range(matches.size()):
				var marker: RegExMatch = matches[offset]
				var end: int = matches[offset + 1].get_start() if offset + 1 < matches.size() else text.length()
				append_text(lines, ACTORS[marker.get_string(1)], text.substr(marker.get_end(), end - marker.get_end()))
		if section != "ending": lines.append({"speaker": "portador", "text": ANSWERS[index]})
		elif index == 4: lines.append({"speaker": "portador", "text": "Mañana habrá trabajo. Esta noche, la luz se queda."})
	var background: String = CampaignRoute.zone(index).background_path
	if background.is_empty(): background = "res://assets/menu/ruinas_menu.png"
	return {"id": "%d:%s" % [index, section], "title": chapter.title, "subtitle": TITLES[section], "background": background, "lines": lines}

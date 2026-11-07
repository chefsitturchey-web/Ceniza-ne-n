class_name OnlineRanking
extends RefCounted
## Ranking online del Boss Rush (API en la web de Cloudflare). Nunca bloquea el juego:
## las victorias se guardan en una cola local y se envían cuando hay conexión.
const URL: String = "https://ceniza-neon.chefsitturchey.workers.dev/api/ranking"
const PENDING_PATH: String = "user://boss_rush_online.cfg"
const TIMEOUT: float = 8.0
## En pruebas headless no se toca la red.
static var enabled: bool = DisplayServer.get_name() != "headless"
static var sending: bool = false

static func pending() -> Array:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PENDING_PATH) != OK: return []
	return config.get_value("online", "pending", [])

static func store_pending(list: Array) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("online", "pending", list)
	config.save(PENDING_PATH)

## Añade una victoria a la cola y trata de enviarla.
static func queue(tree: SceneTree, player: String, seconds: float, hit_count: int) -> void:
	var list: Array = pending()
	list.append({"name": player, "seconds": snappedf(seconds, 0.1), "hits": hit_count,
		"version": str(ProjectSettings.get_setting("application/config/version", ""))})
	store_pending(list)
	flush(tree)

## Envía la cola de una en una. El HTTPRequest cuelga de la raíz para sobrevivir al cambio de escena.
static func flush(tree: SceneTree) -> void:
	if not enabled or sending or tree == null: return
	var list: Array = pending()
	if list.is_empty(): return
	sending = true
	var request: HTTPRequest = HTTPRequest.new()
	request.timeout = TIMEOUT
	tree.root.add_child(request)
	request.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		request.queue_free()
		sending = false
		# Enviado, o rechazado por datos inválidos: sale de la cola. Sin red o error del servidor: se reintenta luego.
		if result == HTTPRequest.RESULT_SUCCESS and (code < 300 or (code >= 400 and code < 500 and code != 429)):
			var rest: Array = pending()
			if not rest.is_empty(): rest.pop_front()
			store_pending(rest)
			flush(tree))
	var error: int = request.request(URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(list[0]))
	if error != OK:
		request.queue_free()
		sending = false

## Pide el top online. done recibe un Array de {name, seconds, hits} o null si no hay conexión.
static func fetch_top(owner: Node, done: Callable) -> void:
	if not enabled:
		done.call(null)
		return
	var request: HTTPRequest = HTTPRequest.new()
	request.timeout = TIMEOUT
	owner.add_child(request)
	request.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		request.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			done.call(null)
			return
		var data: Variant = JSON.parse_string(body.get_string_from_utf8())
		done.call(data.get("ranking", null) if data is Dictionary else null))
	if request.request(URL) != OK:
		request.queue_free()
		done.call(null)

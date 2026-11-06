class_name BossHints
extends Node
## Pistas breves de controles y mecánicas durante cada combate de jefe. Cada pista sale
## una sola vez por pelea, con la tecla o el botón del último dispositivo usado.
## La arena llama a advance() desde su _process: con pausa o novela abierta no avanza.
const DURATION: float = 4.5
const URGENT: Array[String] = ["expuesto", "melee", "lunge"]
## Recuerda el último dispositivo entre arenas (Boss Rush encadena varias).
static var last_pad: bool:
	get: return InputGlyphs.last_pad
	set(value): InputGlyphs.last_pad = value
var arena: RecaudadorArena
var boss: Recaudador
var shown: Dictionary = {}
var queue: Array[String] = []
var current: String = ""
var left: float = 0
var clock: float = 0
var start_delay: float = 0.8
var label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	boss = arena.boss
	start_delay = 2.6 if BossSpectacle.wants(boss) else 0.8
	label = Label.new()
	label.name = "BossHint"
	label.position = Vector2(90, 268)
	label.size = Vector2(460, 34)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", TextMarks.FONT)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("dcf6ee"))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color("08111c"))
	var backing: StyleBoxFlat = StyleBoxFlat.new()
	backing.bg_color = Color("08111c", 0.72)
	backing.border_color = Color("ffce75", 0.35)
	backing.border_width_top = 1
	backing.content_margin_left = 8
	backing.content_margin_right = 8
	label.add_theme_stylebox_override("normal", backing)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate.a = 0
	arena.add_child(label)
	TextMarks.attach(label)
	# Debajo de la pausa, las opciones y la pantalla de resultados.
	arena.move_child(label, arena.combat_hud.get_index() + 1)
	boss.hit_feedback.connect(func(blocked: bool) -> void:
		if blocked: push("bloqueo"))
	boss.phase_changed.connect(func(number: int) -> void:
		if number == 2: push("fase"))

func _input(event: InputEvent) -> void:
	InputGlyphs.observe(event)

## Nombre visible de la acción según el dispositivo: teclado o mando.
static func control(action: String) -> String:
	return "[%s]" % InputGlyphs.action_name(action)

func text_for(id: String) -> String:
	match id:
		"controles": return "Ataca con %s y esquiva con %s: durante la esquiva eres invulnerable." % [control("attack"), control("dodge")]
		"mecanica":
			match arena.zone_index:
				0: return "Su frente bloquea tus golpes: atácalo por los lados o la espalda. Si embiste contra un pilar queda aturdido."
				1: return "Su coraza resiste. Después de las rejillas de fuego purga vapor y su núcleo queda expuesto."
				2: return "Solo recibe daño con el núcleo abierto: rompe las tres antenas con %s y cruza los pulsos por su hueco." % control("attack")
				3: return "Golpear su escudo provoca un contraataque. Espera a que termine un ataque y castiga su recuperación."
				4: return "Protege dos relés: junto a uno pulsa %s para repararlo y %s para blindarlos. Al llenarse el enlace queda expuesta." % [control("interact"), control("overload")]
		"melee": return "Golpe cercano: la zona roja es su alcance exacto. Sal de ella o esquiva con %s justo antes del impacto." % control("dodge")
		"lunge": return "Embestida corta: la línea roja marca su recorrido. Apártate de lado."
		"expuesto": return "Núcleo expuesto: acércate y ataca con %s. Ahora recibe el doble de daño." % control("attack")
		"bloqueo": return "Golpe bloqueado. Si insistes contra su defensa te empujará: busca otro ángulo o espera la apertura."
		"marcas": return "Las runas del suelo estallan cuando su anillo se cierra: sal del círculo a tiempo."
		"fase": return "Segunda fase: avisos más cortos y un golpe más en cada combo."
	return ""

## Encola una pista si aún no salió en esta pelea. Las urgentes pasan delante.
func push(id: String) -> void:
	if shown.has(id) or id in queue or text_for(id).is_empty(): return
	if id in URGENT:
		queue.push_front(id)
		if not current.is_empty() and current not in URGENT:
			# La pista interrumpida pronto vuelve detrás de la urgente.
			if DURATION - left < 2.0:
				shown.erase(current)
				queue.insert(1, current)
			left = minf(left, 0.3)
			current = ""
	else:
		queue.append(id)

## Una línea centrada si cabe; si no, hasta tres líneas a todo el ancho, siempre sobre la barra del jefe.
func fit_label() -> void:
	var width: float = TextMarks.FONT.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20
	label.size = Vector2(width, 20) if width <= 470 else Vector2(520, 54)
	label.position = Vector2(320 - label.size.x / 2, 300 - label.size.y)

func advance(delta: float) -> void:
	if arena.ending or boss.health <= 0:
		label.modulate.a = move_toward(label.modulate.a, 0, delta * 4)
		return
	clock += delta
	if clock >= start_delay:
		push("controles")
		push("mecanica")
	if boss.melee_active(): push("lunge" if boss.melee.kind == "lunge" else "melee")
	if boss.core_exposed: push("expuesto")
	if (boss is CoroSumergido and not (boss as CoroSumergido).marks.is_empty()) or (boss is MadreCero and (boss as MadreCero).marks.any(func(mark: Dictionary) -> bool: return mark.relay < 0)):
		push("marcas")
	left -= delta
	if left <= 0:
		current = ""
		if not queue.is_empty():
			current = queue.pop_front()
			shown[current] = true
			label.text = text_for(current)
			fit_label()
			left = DURATION
	if not current.is_empty():
		var updated: String = text_for(current)
		if label.text != updated:
			label.text = updated
			fit_label()
	label.modulate.a = move_toward(label.modulate.a, 1.0 if not current.is_empty() and left > 0.25 else 0.0, delta * 5)

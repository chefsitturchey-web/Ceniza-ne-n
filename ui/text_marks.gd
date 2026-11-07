class_name TextMarks
extends RichTextLabel
## Capa de lectura: conserva el texto y las medidas de Label para el HUD y sus consumidores.
const KEY: String = "#ffce75"
const TARGET: String = "#47dacb"
const DANGER: String = "#dd6482"
const SPEAKER: String = "#c6a0e8"
const FONT: Font = preload("res://assets/fonts/Silkscreen-Regular.ttf")
const TARGETS: String = "chatarra|piezas|energía|datos|núcleos?|objetivos?|baterías?|murallas|torretas|herramientas|habitantes|campamento|arsenal|clínica|refugio|población|relés|antenas|pilar|diario|colonia|puntos|mejorar|equipar|evolucionar|construye|repara|recupera|levántalo|levanta|recluta|compra|amplía|repararlo|blindarlos|expuesto|expuesta|aturdido|coberturas?|pared|escudo agotado|enlaces|protocolo|apertura|recuperación|invulnerable|comprar|fabricar|construir|reparar|levantar|defiende|rescata|ataca|esquiva|interactuar|esquivar|atacar|asaltar|retirar|vida reparada|filo mejorado|siguiente|jefes derrotados|mejor tiempo|récord"
const DANGERS: String = "peligro|amenaza|invasión|enemigos?|embestida|impacto|zona roja|línea roja|contraataque|fuego|pulsos|estocada|barrido|salva|garrazo|calor activo|escoria|arremetida|proyectiles|runas|marcas|estallan|golpe bloqueado|segunda fase|golpes recibidos|señal perdida|núcleo destruido"
var source: Control
var template: String = ""
var previous: String = "\u0001"
var base_color: Color
var theme_dirty: bool = true
var glyph_stamp: String = ""

static func color_text(value: String, tint: String) -> String:
	return "[color=%s]%s[/color]" % [tint, value]

static func escape(value: String) -> String:
	return value.replace("[", "[lb]")

## Las marcas se calculan sobre texto plano; nunca se interpretan etiquetas del contenido.
static func format_text(value: String) -> String:
	var keys: PackedStringArray = []
	for action: String in KeyRemap.DEFAULTS:
		var key: String = InputGlyphs.action_name(action)
		for special: String in ["\\", ".", "+", "*", "?", "(", ")", "[", "]", "{", "}", "^", "$", "|"]:
			key = key.replace(special, "\\" + special)
		if not key.is_empty(): keys.append(key)
	keys.append("Cambiar")
	var key_pattern: String = "(?<![\\p{L}\\p{N}_])(?:" + "|".join(keys) + ")(?![\\p{L}\\p{N}_])"
	var pattern: RegEx = RegEx.new()
	pattern.compile(key_pattern + "|(?i:(?<![\\p{L}\\p{N}_])(" + DANGERS + "|" + TARGETS + ")(?![\\p{L}\\p{N}_]))|(?:MARA|IVO|VERA|NOX|ECO|PORTADOR):|\\[[^\\]\\n]+\\]|\\{[a-z_]+\\}")
	var output: String = ""
	var start: int = 0
	for found: RegExMatch in pattern.search_all(value):
		output += escape(value.substr(start, found.get_start() - start))
		var word: String = found.get_string()
		var tint: String = KEY if word in glyph_names() or word == "Cambiar" else TARGET
		if word.begins_with("{"):
			var action: String = word.trim_prefix("{").trim_suffix("}")
			if action in KeyRemap.DEFAULTS or action in ["move", "mute"]: word = InputGlyphs.action_name(action)
			tint = KEY
		elif word.begins_with("["):
			tint = KEY
		elif word.ends_with(":"):
			tint = SPEAKER if word.trim_suffix(":").to_upper() in ["MARA", "IVO", "VERA", "NOX", "ECO", "PORTADOR"] else TARGET
		else:
			var danger: RegEx = RegEx.new()
			danger.compile("(?i)^(" + DANGERS + ")$")
			if danger.search(word) != null: tint = DANGER
		# Botones de PlayStation con su color: ✕ azul, ○ rojo, □ rosa, △ verde.
		var pad: Color = InputGlyphs.pad_color(word)
		if tint == KEY and pad.a > 0: tint = "#" + pad.to_html(false)
		var marked: String = color_text(escape(word), tint)
		output += "[bgcolor=#172736]" + marked + "[/bgcolor]" if tint == KEY or pad.a > 0 else marked
		start = found.get_end()
	return output + escape(value.substr(start))

static func glyph_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for action: String in KeyRemap.DEFAULTS: names.append(InputGlyphs.action_name(action))
	return names

static func attach(label: Control, marked_template: String = "") -> TextMarks:
	var layer: TextMarks = TextMarks.new()
	layer.source = label
	layer.template = marked_template
	label.add_child(layer)
	return layer

func _ready() -> void:
	name = "TextMarks"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bbcode_enabled = true
	scroll_active = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base_color = source.get_theme_color("font_color")
	if source is Label:
		source.self_modulate.a = 0
	else:
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
			source.add_theme_color_override(state, Color.TRANSPARENT)
	source.theme_changed.connect(func() -> void: theme_dirty = true)
	process_priority = 110
	refresh()

func _process(_delta: float) -> void:
	if source.is_visible_in_tree(): refresh()

func refresh() -> void:
	if theme_dirty:
		var font: Font = source.get_theme_font("font")
		var font_size: int = source.get_theme_font_size("font_size")
		add_theme_font_override("normal_font", font)
		add_theme_font_size_override("normal_font_size", font_size)
		add_theme_color_override("default_color", base_color)
		add_theme_color_override("font_outline_color", source.get_theme_color("font_outline_color"))
		add_theme_constant_override("outline_size", source.get_theme_constant("outline_size"))
		add_theme_constant_override("line_separation", source.get_theme_constant("line_spacing"))
		if source is Label: add_theme_stylebox_override("normal", source.get_theme_stylebox("normal"))
		theme_dirty = false
	position = Vector2.ZERO
	size = source.size
	if source is Label:
		horizontal_alignment = (source as Label).horizontal_alignment
		vertical_alignment = (source as Label).vertical_alignment
		autowrap_mode = (source as Label).autowrap_mode
	else:
		horizontal_alignment = (source as Button).alignment
		var box: StyleBox = source.get_theme_stylebox("normal")
		position.x = box.get_content_margin(SIDE_LEFT)
		size.x -= position.x + box.get_content_margin(SIDE_RIGHT)
		vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var plain: String = source.get("text")
	var content: String = template if not template.is_empty() else plain
	var stamp: String = "|".join(glyph_names())
	if content != previous or stamp != glyph_stamp:
		glyph_stamp = stamp
		text = format_text(content)
		previous = content

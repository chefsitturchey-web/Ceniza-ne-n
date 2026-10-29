class_name MusicLibrary
extends RefCounted
## Repertorio musical. Las listas permiten elegir variantes al azar sin tocar el resto del código.

const MENU: AudioStream = preload("res://assets/audio/music/menu.ogg")
const NIGHT: AudioStream = preload("res://assets/audio/music/colonia_noche.ogg")
const WARNING: AudioStream = preload("res://assets/audio/music/aviso.ogg")
const VICTORY: AudioStream = preload("res://assets/audio/music/victoria.ogg")
const DEFEAT: AudioStream = preload("res://assets/audio/music/derrota.ogg")

## Un tema por distrito; las zonas con dos variantes alternan en cada partida.
const DAY: Dictionary = {
	"periphery": [preload("res://assets/audio/music/colonia_dia.ogg")],
	"foundry": [preload("res://assets/audio/music/zona_fundicion.ogg"), preload("res://assets/audio/music/zona_fundicion_b.ogg")],
	"flooded": [preload("res://assets/audio/music/zona_inundado.ogg")],
	"citadel": [preload("res://assets/audio/music/zona_ciudadela.ogg")],
	"network": [preload("res://assets/audio/music/zona_red.ogg"), preload("res://assets/audio/music/zona_red_b.ogg")],
}

## Todos los temas de jefe comparten bolsa: cualquier combate puede usar cualquiera.
const BOSS: Array[AudioStream] = [
	preload("res://assets/audio/music/jefe_recaudador.ogg"),
	preload("res://assets/audio/music/jefe_caldera.ogg"),
	preload("res://assets/audio/music/jefe_caldera_b.ogg"),
	preload("res://assets/audio/music/jefe_prefecto.ogg"),
	preload("res://assets/audio/music/jefe_prefecto_b.ogg"),
	preload("res://assets/audio/music/jefe_madrecero.ogg"),
	preload("res://assets/audio/music/jefe_alt_1.ogg"),
	preload("res://assets/audio/music/jefe_alt_2.ogg"),
	preload("res://assets/audio/music/jefe_alt_3.ogg"),
]

static func day_for(zone_id: String, rng: RandomNumberGenerator) -> AudioStream:
	var pool: Array = DAY.get(zone_id, DAY["periphery"]) as Array
	var picked: AudioStream = pool[rng.randi_range(0, pool.size() - 1)] as AudioStream
	return picked

static func boss_for(rng: RandomNumberGenerator) -> AudioStream:
	var picked: AudioStream = BOSS[rng.randi_range(0, BOSS.size() - 1)]
	return picked

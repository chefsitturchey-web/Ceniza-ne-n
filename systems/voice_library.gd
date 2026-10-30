class_name VoiceLibrary
extends RefCounted
## Voces de diálogo: 5 timbres x 4 emociones x 5 alturas, cargadas bajo demanda.

const CHARACTERS: Array[String] = ["protagonista", "rival", "anciano", "criatura", "robot"]
const EMOTIONS: Array[String] = ["neutral", "feliz", "triste", "enojado"]
const VARIANTS: int = 5
const BASE: String = "res://assets/audio/sfx/8bit/voz/voz_%s_%s_v%d.wav"

## Hablante de la historia -> personaje con timbre propio.
const SPEAKER_CHARACTER: Dictionary = {
	"portador": "protagonista",
	"mara": "anciano",
	"ivo": "rival",
	"vera": "criatura",
	"nox": "rival",
	"eco": "robot",
	"prefect": "robot",
	"mother": "robot",
	"narrator": "anciano"
}

## Semitonos extra para los hablantes que comparten personaje.
const SPEAKER_SHIFT: Dictionary = {
	"nox": -2.0,
	"prefect": 3.0,
	"mother": -3.0,
	"narrator": -2.0
}

static var cache: Dictionary = {}

## Sección de la escena -> emoción de la línea.
static func emotion_for(section: String) -> String:
	match section:
		"rescue":
			return "triste"
		"convoy":
			return "feliz"
		"encounter":
			return "enojado"
		"ending":
			return "feliz"
	return "neutral"

static func stream_for(speaker: String, emotion: String, variant: int) -> AudioStream:
	var character: String = String(SPEAKER_CHARACTER.get(speaker, "anciano"))
	var mood: String = emotion if emotion in EMOTIONS else "neutral"
	var path: String = BASE % [character, mood, clampi(variant, 1, VARIANTS)]
	if not cache.has(path):
		cache[path] = load(path)
	return cache[path] as AudioStream

static func shift_for(speaker: String) -> float:
	return float(SPEAKER_SHIFT.get(speaker, 0.0))

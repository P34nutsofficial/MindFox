extends RefCounted
class_name AvatarCatalog

const NAMES := ["SHERLOCK", "DER GANOVE", "DER CLOWN", "AREA 51", "PURR-FECT", "FOXY", "IMP", "GLITCH"]
const LABELS := ["🔎", "🕶️", "🎭", "👽", "🐱", "🦊", "😈", "🤖"]
const TINTS := ["CYAN", "GOLD", "VIOLETT", "LIMETTE", "KORALLE"]
const EXPRESSIONS := ["POKERFACE", "GRINSEN", "SCHOCK", "ZWINKERN"]
const IMAGES: Array[Texture2D] = [
	preload("res://assets/avatars/avatar_sherlock.png"),
	preload("res://assets/avatars/avatar_ganove.png"),
	preload("res://assets/avatars/avatar_clown.png"),
	preload("res://assets/avatars/avatar_alien.png"),
	preload("res://assets/avatars/avatar_cat.png"),
	preload("res://assets/avatars/avatar_fox.png"),
	preload("res://assets/avatars/avatar_imp.png"),
	preload("res://assets/avatars/avatar_glitch.png")
]

static func clamp_index(index: int) -> int:
	return clampi(index, 0, NAMES.size() - 1)

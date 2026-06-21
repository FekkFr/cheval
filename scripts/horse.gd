# La classe cheval
class_name Horse
extends RefCounted

# Stats visibles par le joueur
var horse_name: String
var form: int
var stamina: int
var track_fit: int

# Données internes
var final_score: int = 0
var modifiers: Array = []

func _init(p_name: String, p_form: int, p_stamina: int, p_track: int):
	horse_name = p_name
	form       = p_form
	stamina    = p_stamina
	track_fit  = p_track

func calculate_score() -> int:
	var base = (form * 0.4) + (stamina * 0.3) + (track_fit * 0.3)
	var rand_factor = randi_range(-15, 15)
	var mod_bonus = get_modifier_bonus()
	return clampi(int(base) + rand_factor + mod_bonus, 0, 100)

func get_modifier_bonus() -> int:
	var total = 0
	for mod in modifiers:
		total += mod.score_delta
	return total

static func generate_random(p_name: String) -> Horse:
	return Horse.new(
		p_name,
		randi_range(30, 95),
		randi_range(30, 95),
		randi_range(30, 95)
	)

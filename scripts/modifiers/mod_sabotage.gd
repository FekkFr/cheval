# Modificateur : Sabotage
# Réduit le score d'un cheval ciblé de 20 points
class_name ModSabotage
extends ModifierBase

func _init():
	mod_id = "mod_sabotage"
	mod_name = "Sabotage"
	description = "Réduit les chances d'un cheval de 20pts. Discret."
	cost = 2
	duration = 1  # dure 1 course
	icon = "🔧"
	unlocked_by_default = true
	needs_target = true

func on_before_race(horses: Array) -> void:
	if target_index < horses.size():
		horses[target_index].modifiers.append({"score_delta": -20})
		print("[SABOTAGE] ", horses[target_index].horse_name, " sabotée (-20 pts)")

# Modificateur : Sabotage Discret
# Réduit le score d'un cheval ciblé de 20 points mais sans suspicion gain
class_name ModSabotageDiscret
extends ModifierBase

func _init():
	mod_id = "mod_sabotage_discret"
	mod_name = "Sabotage Discret"
	description = "Réduit les chances d'un cheval de 20pts. Discret."
	cost = 3
	duration = 1 
	icon = "🔧"
	unlocked_by_default = true
	needs_target = true
	suspicion_gain = 0 

func on_before_race(horses: Array) -> void:
	if target_index < horses.size():
		horses[target_index].modifiers.append({"score_delta": -20})
		print("[SABOTAGE] ", horses[target_index].horse_name, " sabotée (-20 pts)")

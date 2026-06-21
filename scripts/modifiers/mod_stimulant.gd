# Modificateur : Stimulant
class_name ModStimulant
extends ModifierBase

func _init():
	mod_id = "mod_stimulant"
	mod_name = "Stimulant"
	description = "Booste un cheval de +25pts."
	cost = 0
	duration = 1  # dure 1 course
	icon = "💉"
	unlocked_by_default = true
	needs_target = true

func on_before_race(horses: Array) -> void:
	if target_index < horses.size():
		horses[target_index].modifiers.append({"score_delta": +25})
		print("[Stimuler] ", horses[target_index].horse_name, " Stimuler (+25 pts)")

# Modificateur : Desktop
# Change le nombre d'objet qu'on peut obtenir sur le bureau
class_name ModDesk
extends ModifierBase

func _init():
	mod_id = "mod_deskupgrade"
	mod_name = "Desktop"
	description = "Permet de rajouter 1 objet sur le bureau"
	cost = 1
	duration = -1
	icon = "🔧"
	unlocked_by_default = true
	needs_target = false

func on_activate() -> void:
	ModifierManager.max_slots += 1
	

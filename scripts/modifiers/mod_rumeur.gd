# Modificateur : Rumeur
# Redirige les mises des parieurs vers un cheval ciblé
class_name ModRumeur
extends ModifierBase

func _init():
	mod_id = "mod_rumeur"
	mod_name = "Rumeur"
	description = "Les parieurs misent 2× plus sur le cheval ciblé."
	cost = 2
	duration = 1
	icon = "📰"
	unlocked_by_default = true
	needs_target = true

func on_calculate_bets(odds: Dictionary) -> Dictionary:
	if target_index < 0: return odds
	# On a besoin du nom du cheval ciblé
	var horses = GameState.current_horses
	if target_index >= horses.size(): return odds
	var target_name = horses[target_index].horse_name
	# Diviser la cote par 2 = les parieurs pensent qu'il est favori
	# → ils misent 2× plus sur lui
	var modified = odds.duplicate()
	if target_name in modified:
		modified[target_name] = maxf(modified[target_name] / 2.0, 1.1)
		print("[RUMEUR] Mises doublées sur ", target_name)
	return modified

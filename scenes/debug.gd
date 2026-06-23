extends Node

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	# F1 — Acheter Sabotage (modificateur avec ciblage)
	if event.keycode == KEY_F1:
		var mod = ModifierManager.get_modifier_by_id("mod_sabotage")
		if mod:
			ModifierManager.buy_modifier(mod)
			print("[DEBUG] Sabotage acheté")
	
	# F2 — Acheter Stimulant
	if event.keycode == KEY_F2:
		var mod = ModifierManager.get_modifier_by_id("mod_stimulant")
		if mod:
			ModifierManager.buy_modifier(mod)
			print("[DEBUG] Stimulant acheté")
	
	# F3 — Ajouter 10 tickets
	if event.keycode == KEY_F3:
		ModifierManager.tickets += 10
		print("[DEBUG] +10 tickets")

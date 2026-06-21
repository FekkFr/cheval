# Gère les modificateurs actifs, les tickets, et les achats
# Autoload sous le nom "ModifierManager"
extends Node

# ── Tickets ───────────────────────────────────────
var tickets: int = 0
const TICKET_PROFIT_THRESHOLD = 200.0  # profit > 200$ = +3 tickets au lieu de +1

signal tickets_changed(new_amount: int)

# ── Slots de modificateurs ────────────────────────
var max_slots: int = 3
var active_modifiers: Array = []  # Array[ModifierBase]

signal modifier_activated(mod: ModifierBase)
signal modifier_expired(mod: ModifierBase)

# ── Catalogue des modificateurs disponibles ───────
# Chargé dynamiquement depuis les scripts
var all_modifiers: Array = []

func _ready():
	_load_all_modifiers()

func _load_all_modifiers() -> void:
	# Charger tous les modificateurs depuis leurs scripts
	# On les instancie ici pour avoir accès à leurs métadonnées
	var mod_scripts = [
		"res://scripts/modifiers/mod_sabotage.gd",
		"res://scripts/modifiers/mod_pari_perso.gd",
		"res://scripts/modifiers/mod_rumeur.gd",
		"res://scripts/modifiers/mod_stimulant.gd",
		"res://scripts/modifiers/mod_jockey.gd",
	]
	for path in mod_scripts:
		print("Cherche : ", path, " → ", ResourceLoader.exists(path))
		if ResourceLoader.exists(path):
			var script = load(path)
			if script:
				var instance = script.new()
				all_modifiers.append(instance)
				print("Chargé : ", instance.mod_name)

# ── Gagner des tickets après une course ───────────
func earn_tickets(profit: float) -> int:
	var earned = 1
	if profit > TICKET_PROFIT_THRESHOLD:
		earned = 3
	tickets += earned
	AchievementManager.total_tickets_earned += earned
	AchievementManager.check_achievements("tickets_total")
	emit_signal("tickets_changed", tickets)
	return earned

# ── Acheter un modificateur ───────────────────────
func buy_modifier(mod: ModifierBase) -> bool:
	print("Tentative achat : ", mod.mod_name)
	print("Tickets : ", tickets, " | Coût : ", mod.cost)
	print("Slots : ", active_modifiers.size(), " / ", max_slots)
	print("Débloqué : ", AchievementManager.is_modifier_unlocked(mod.mod_id))

	for active in active_modifiers:
		if active.mod_id == mod.mod_id:
			print("→ ÉCHEC : modificateur déjà actif")
			return false

	if tickets < mod.cost:
		print("→ ÉCHEC : pas assez de tickets")
		return false
	if active_modifiers.size() >= max_slots:
		print("→ ÉCHEC : slots pleins")
		return false
	if not AchievementManager.is_modifier_unlocked(mod.mod_id):
		print("→ ÉCHEC : verrouillé")
		return false

	tickets -= mod.cost
	emit_signal("tickets_changed", tickets)
	var new_instance = mod.duplicate()
	new_instance.on_activate()
	active_modifiers.append(new_instance)
	emit_signal("modifier_activated", new_instance)
	print("→ SUCCÈS")
	return true
# ── Appliquer les modificateurs avant la course ───
func apply_before_race(horses: Array) -> void:
	for mod in active_modifiers:
		mod.on_before_race(horses)

# ── Appliquer les modificateurs après la course ───
func apply_after_race(profit: float, winner) -> float:
	var modified_profit = profit
	for mod in active_modifiers:
		modified_profit = mod.on_after_race(modified_profit, winner)
	return modified_profit

func apply_on_bets(odds: Dictionary) -> Dictionary:
	var modified = odds.duplicate()
	for mod in active_modifiers:
		modified = mod.on_calculate_bets(modified)
	return modified

# ── Tick après chaque course (décrémenter durées) ─
func tick_all() -> void:
	var expired = []
	for mod in active_modifiers:
		if not mod.tick():
			expired.append(mod)
	for mod in expired:
		active_modifiers.erase(mod)
		emit_signal("modifier_expired", mod)
		print("[MOD] Expiré : ", mod.mod_name)

# ── Obtenir les mods disponibles à la boutique ────
func get_shop_modifiers(count: int = 3) -> Array:
	var available = []
	for mod in all_modifiers:
		if AchievementManager.is_modifier_unlocked(mod.mod_id):
			available.append(mod)
	available.shuffle()
	return available.slice(0, min(count, available.size()))

# ── Reset entre les runs ─────────────────────────
func reset_run() -> void:
	active_modifiers.clear()
	tickets = 0
	emit_signal("tickets_changed", tickets)

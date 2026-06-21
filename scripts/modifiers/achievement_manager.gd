# Gère les achievements et les déblocages permanents
# Autoload sous le nom "AchievementManager"
extends Node

# ── Achievements disponibles ──────────────────────
# Chaque achievement a : id, description, condition, modificateur débloqué
const ACHIEVEMENTS = [
	{
		"id": "survivor_3",
		"name": "Survivant",
		"desc": "Survivre 3 semaines",
		"unlocks": "mod_rumeur"
	},
	{
		"id": "survivor_5",
		"name": "Vétéran",
		"desc": "Survivre 5 semaines",
		"unlocks": "mod_jockey"
	},
	{
		"id": "big_profit",
		"name": "Coup de maître",
		"desc": "Faire +500$ de profit sur une course",
		"unlocks": "mod_stimulant"
	},
	{
		"id": "tickets_20",
		"name": "Collectionneur",
		"desc": "Accumuler 20 tickets au total",
		"unlocks": "mod_inspecteur"
	},
	{
		"id": "pari_win_5",
		"name": "Parieur",
		"desc": "Gagner 5 paris personnels",
		"unlocks": "mod_double_mise"
	}
]

# ── Données persistantes ──────────────────────────
var unlocked_achievements: Array = []    # ids des achievements obtenus
var unlocked_modifiers: Array = []       # ids des modificateurs débloqués
var total_tickets_earned: int = 0        # tickets gagnés au total (tous runs)
var total_pari_wins: int = 0             # paris gagnés au total

# ── Sauvegarde ────────────────────────────────────
const SAVE_PATH = "user://achievements.json"

func _ready():
	load_data()

func save_data() -> void:
	var data = {
		"unlocked_achievements": unlocked_achievements,
		"unlocked_modifiers": unlocked_modifiers,
		"total_tickets_earned": total_tickets_earned,
		"total_pari_wins": total_pari_wins
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		# Premier lancement - débloquer les mods de base
		unlocked_modifiers = ["mod_sabotage", "mod_pari_perso", "mod_stimulant", "mod_rumeur"]
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data:
			unlocked_achievements = data.get("unlocked_achievements", [])
			unlocked_modifiers = data.get("unlocked_modifiers", ["mod_sabotage", "mod_pari_perso"])
			total_tickets_earned = data.get("total_tickets_earned", 0)
			total_pari_wins = data.get("total_pari_wins", 0)

# ── Vérifier les achievements après chaque événement ─
func check_achievements(event: String, value: float = 0) -> Array:
	var newly_unlocked = []

	match event:
		"week_survived":
			if int(value) >= 3 and not "survivor_3" in unlocked_achievements:
				_unlock("survivor_3", newly_unlocked)
			if int(value) >= 5 and not "survivor_5" in unlocked_achievements:
				_unlock("survivor_5", newly_unlocked)
		"big_profit":
			if value >= 500 and not "big_profit" in unlocked_achievements:
				_unlock("big_profit", newly_unlocked)
		"tickets_total":
			if total_tickets_earned >= 20 and not "tickets_20" in unlocked_achievements:
				_unlock("tickets_20", newly_unlocked)
		"pari_win":
			total_pari_wins += 1
			if total_pari_wins >= 5 and not "pari_win_5" in unlocked_achievements:
				_unlock("pari_win_5", newly_unlocked)

	if newly_unlocked.size() > 0:
		save_data()
	return newly_unlocked

func _unlock(achievement_id: String, newly_unlocked: Array) -> void:
	unlocked_achievements.append(achievement_id)
	# Trouver le modificateur à débloquer
	for ach in ACHIEVEMENTS:
		if ach["id"] == achievement_id:
			var mod_id = ach["unlocks"]
			if not mod_id in unlocked_modifiers:
				unlocked_modifiers.append(mod_id)
				newly_unlocked.append({"achievement": ach["name"], "mod": mod_id})
			break

# ── Vérifier si un mod est débloqué ──────────────
func is_modifier_unlocked(mod_id: String) -> bool:
	return mod_id in unlocked_modifiers

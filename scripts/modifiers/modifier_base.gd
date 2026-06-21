# Classe parente de tous les modificateurs
class_name ModifierBase
extends Resource

# ── Infos affichées dans la boutique ─────────────
@export var mod_id: String        # identifiant unique ex: "sabotage"
@export var mod_name: String      # nom affiché ex: "Palefrenier Corrompu"
@export var description: String   # description courte
@export var cost: int             # coût en tickets
@export var duration: int         # nombre de courses (-1 = permanent)
@export var icon: String = "🃏"   # emoji pour l'UI proto
# ── Déblocage ─────────────────────────────────────
@export var unlocked_by_default: bool = false
@export var unlock_achievement: String = ""  # id de l'achievement requis
# ── Target Ciblage ─────────────────────────────────────
@export var needs_target: bool = false
var target_index: int = -1
# ── État interne ──────────────────────────────────
var courses_remaining: int = 0   # courses restantes avant expiration

# ── Méthodes à override dans chaque modificateur ─

# Appelé quand le modificateur est acheté/activé
func on_activate() -> void:
	courses_remaining = duration
	print("[MOD] Activé : ", mod_name)

# Appelé avant chaque course (pour modifier les chevaux)
func on_before_race(horses: Array) -> void:
	pass

# Appelé après chaque course (pour modifier le profit)
func on_after_race(profit: float, winner) -> float:
	return profit  # retourne le profit modifié

# Appelé à la fin de chaque course pour décrémenter la durée
func tick() -> bool:
	if duration == -1:
		return true  # permanent, ne jamais expirer
	courses_remaining -= 1
	return courses_remaining > 0  # false = expiré

# Texte affiché dans le HUD quand actif
func get_status_text() -> String:
	if duration == -1:
		return icon + " " + mod_name
	return icon + " " + mod_name + " (" + str(courses_remaining) + ")"

func on_calculate_bets(odds: Dictionary) -> Dictionary:
	return odds  # par défaut ne change rien

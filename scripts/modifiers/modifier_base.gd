# Classe parente de tous les modificateurs
#
# ══════════════════════════════════════════════════════════════
# COMMENT AJOUTER UN NOUVEL OBJET (MODIFICATEUR)
# ══════════════════════════════════════════════════════════════
# Un objet = un script qui extends ModifierBase. Étapes :
#
# 1. Créer scripts/modifiers/mod_XXX.gd avec class_name ModXXX
#    extends ModifierBase, et un _init() qui remplit les @export
#    ci-dessous (mod_id, mod_name, description, cost, duration,
#    icon, needs_target, suspicion_gain...).
#
# 2. Donner un comportement à l'objet en overridant UNE ou
#    plusieurs des méthodes définies plus bas dans ce fichier :
#      - on_before_race(horses)        → buff/debuff un cheval
#        (ex: mod_sabotage.gd -20pts, mod_stimulant.gd +25pts)
#      - on_calculate_bets(odds)       → manipuler cotes/mises
#        (ex: mod_rumeur.gd)
#      - on_after_race(profit, winner) → modifier le profit final
#      - on_activate()                 → effet immédiat à l'achat
#        (rare : la base gère déjà courses_remaining = duration)
#
# 3. Enregistrer le script dans ModifierManager._load_all_modifiers()
#    (scripts/modifiers/modifiermanager.gd) → ajouter son chemin
#    dans le tableau mod_scripts. Sans ça l'objet n'existe pas en jeu.
#
# 4. Débloquer l'objet — choisir UNE des deux options :
#      a) Dispo dès le début : ajouter mod_id à la liste par défaut
#         dans AchievementManager.load_data() (achievement_manager.gd).
#         ⚠ unlocked_by_default = true seul ne suffit PAS : ce champ
#         n'est actuellement lu nulle part, get_shop_modifiers() ne
#         regarde que AchievementManager.is_modifier_unlocked().
#      b) Réservé à un achievement : ajouter une entrée dans
#         AchievementManager.ACHIEVEMENTS avec "unlocks": "mod_XXX"
#         (et remplir unlock_achievement sur le mod pour l'afficher).
#
# 5. Si l'objet cible un cheval (needs_target = true), rien à faire
#    côté UI : cliquer un pion dans la pièce 3D (PionManager, dans
#    scripts/world/pion_manager.gd) assigne déjà target_index tout
#    seul après l'achat.
#
# 6. Tester : lancer le jeu, l'acheter en boutique, vérifier l'effet
#    (les print() dans on_before_race etc. aident à debug).
# ══════════════════════════════════════════════════════════════
class_name ModifierBase
extends Resource

@export var mod_id: String   
@export var mod_name: String     
@export var description: String  
@export var cost: int         
@export var duration: int   
@export var icon: String = "🃏"  

@export var unlocked_by_default: bool = false
@export var unlock_achievement: String = "" 

@export var needs_target: bool = false
var target_index: int = -1

@export var suspicion_gain: float = 0.0

var courses_remaining: int = 0 
var used: bool = false          

func on_activate() -> void:
	courses_remaining = duration
	print("[MOD] Activé : ", mod_name)

func on_before_race(horses: Array) -> void:
	pass

func on_after_race(profit: float, winner) -> float:
	return profit  # retourne le profit modifié

func tick() -> bool:
	if duration == -1:
		return true  # permanent, ne jamais expirer
	courses_remaining -= 1
	return courses_remaining > 0  # false = expiré

func get_status_text() -> String:
	if duration == -1:
		return icon + " " + mod_name
	return icon + " " + mod_name + " (" + str(courses_remaining) + ")"

func on_calculate_bets(odds: Dictionary) -> Dictionary:
	return odds 

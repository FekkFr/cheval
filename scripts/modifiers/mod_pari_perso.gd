# Modificateur : Pari Personnel
# Permet de miser sur un cheval avec mise max 30% de la caisse
class_name ModPariPerso
extends ModifierBase

func _init():
	mod_id = "mod_pari_perso"
	mod_name = "Pari Personnel"
	description = "Mise jusqu'à 30% de ta caisse sur un cheval pour cette course."
	cost = 1
	duration = 1  # une seule course
	icon = "🎰"
	unlocked_by_default = true

# La logique du pari est gérée directement dans main.gd
# Ce modificateur sert juste à l'afficher dans la boutique
# et à vérifier s'il est actif
func on_after_race(profit: float, winner) -> float:
	return profit  # la logique est dans main.gd

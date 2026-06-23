class_name Bookmaker

const POOL_SIZE = 1000.0
const MIN_SPREAD = 0.5   # écart minimal entre cotes pour ne pas être pénalisé
const FULL_SPREAD = 4.0  # écart à partir duquel le pool est à son maximum

func calculate_bets(odds: Dictionary) -> Dictionary:
	var total_weight = 0.0
	for name in odds:
		total_weight += 1.0 / odds[name]

	var effective_pool = POOL_SIZE * _spread_multiplier(odds)

	var bets = {}
	for name in odds:
		var weight = (1.0 / odds[name]) / total_weight
		bets[name] = effective_pool * weight

	return bets

func calculate_profit(winner_name: String, odds: Dictionary, bets: Dictionary) -> float:
	var total_collected = 0.0
	for name in bets:
		total_collected += bets[name]
	var payout = bets[winner_name] * odds[winner_name]
	return total_collected - payout

func suggest_odds(horses: Array) -> Dictionary:
	var odds = {}
	for horse in horses:
		var avg = (horse.form + horse.stamina + horse.track_fit) / 3.0
		odds[horse.horse_name] = lerp(8.0, 1.5, avg / 100.0)
	return odds

# ── Calcule un multiplicateur de pool selon l'écart entre cotes ──
# Cotes plates (écart faible) → pool très réduit → quasi aucun profit possible.
# Cotes très différenciées (vrai pari) → pool complet, voire bonus → vrai potentiel de gain.
func _spread_multiplier(odds: Dictionary) -> float:
	var values = odds.values()
	var min_odd = values.min()
	var max_odd = values.max()
	var spread = max_odd - min_odd

	if spread <= MIN_SPREAD:
		# Très peu de risque pris → pool réduit à 15% (quasi aucun profit possible)
		return 0.15

	if spread >= FULL_SPREAD:
		# Vrai pari tranché → pool complet, légère prime pour la prise de risque
		return 1.0

	# Entre les deux : interpolation progressive
	var t = (spread - MIN_SPREAD) / (FULL_SPREAD - MIN_SPREAD)
	return lerp(0.15, 1.0, t)

# Utile pour l'UI : donne le multiplicateur actuel, pour afficher un feedback au joueur
func get_current_spread_multiplier(odds: Dictionary) -> float:
	return _spread_multiplier(odds)

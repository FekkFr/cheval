class_name Bookmaker
extends RefCounted

const POOL_SIZE = 1000.0
const MIN_ODDS = 1.1
const MAX_ODDS = 20.0

func calculate_bets(odds: Dictionary) -> Dictionary:
	# Laisser les mods modifier les cotes perçues
	var modified_odds = ModifierManager.apply_on_bets(odds)
	var total_weight = 0.0
	for name in modified_odds:
		total_weight += 1.0 / modified_odds[name]
	var bets = {}
	for name in modified_odds:
		var weight = (1.0 / modified_odds[name]) / total_weight
		bets[name] = POOL_SIZE * weight
	return bets

func calculate_profit(winner_name: String, odds: Dictionary, bets: Dictionary) -> float:
	var payout = bets[winner_name] * odds[winner_name]
	var collected = 0.0
	for name in bets:
		collected += bets[name]
	var profit = collected - payout
	print("Collecté : ", collected, " | Payé : ", payout, " | Profit : ", profit)
	return profit

func suggest_odds(horses: Array) -> Dictionary:
	var suggested = {}
	for horse in horses:
		var avg = (horse.form + horse.stamina + horse.track_fit) / 3.0
		var cote = lerp(8.0, 1.5, avg / 100.0)
		suggested[horse.horse_name] = snappedf(cote, 0.1)
	return suggested

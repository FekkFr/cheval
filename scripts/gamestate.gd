extends Node

enum State {
	MENU,
	BRIEFING,
	SET_ODDS,
	SHOP,
	RACE,
	RESULT,
	DEADLINE,
	GAME_OVER
}

signal race_finished

var state: State = State.MENU
var week: int = 0
var race_in_week: int = 1
var cash: float = 800.0
var debt: float = 10000.0
var weekly_payment: float = 1250.0  # tranche fixe (dette initiale / 8), ne doit pas être recalculée sur la dette restante
var game_over_reason: String = ""

const MAX_SUSPICION: float = 100.0
const SUSPICION_FINE_RATE: float = 0.20  # amende = 20% de la caisse
const WEEKLY_PAYMENT_GROWTH_RATE: float = 0.10  # la tranche augmente de 10% après chaque paiement réussi
var suspicion: float = 0.0

var current_horses: Array = []
var current_odds: Dictionary = {}
var last_result: Array = []
var last_profit: float = 0.0

signal state_changed(new_state: State)
signal cash_changed(new_amount: float)
signal suspicion_changed(new_amount: float)
signal suspicion_fine(fine_amount: float)

func change_state(new_state: State) -> void:
	state = new_state
	emit_signal("state_changed", new_state)
	match new_state:
		State.DEADLINE:
			get_tree().change_scene_to_file("res://scenes/deadline.tscn")
		State.GAME_OVER:
			get_tree().change_scene_to_file("res://scenes/gameover.tscn")

func add_cash(amount: float) -> void:
	cash += amount
	emit_signal("cash_changed", cash)

func get_weekly_payment() -> float:
	return min(weekly_payment, debt)  # jamais plus que ce qu'il reste à rembourser

func add_suspicion(amount: float) -> void:
	suspicion = clampf(suspicion + amount, 0.0, MAX_SUSPICION)
	emit_signal("suspicion_changed", suspicion)
	if suspicion >= MAX_SUSPICION:
		_trigger_suspicion_fine()

func _trigger_suspicion_fine() -> void:
	var fine = cash * SUSPICION_FINE_RATE
	cash -= fine
	emit_signal("cash_changed", cash)
	suspicion = 0.0
	emit_signal("suspicion_changed", suspicion)
	emit_signal("suspicion_fine", fine)
	print("[SUSPICION] Grillé ! Amende de $", int(fine), " — jauge réinitialisée")

func pay_debt() -> bool:
	var payment = get_weekly_payment()
	if cash >= payment:
		cash -= payment
		debt -= payment
		emit_signal("cash_changed", cash)
		weekly_payment *= (1.0 + WEEKLY_PAYMENT_GROWTH_RATE)
		return true
	trigger_game_over("debt")
	return false

func next_race() -> void:
	if race_in_week < 3:
		race_in_week += 1
		change_state(State.BRIEFING)
	else:
		race_in_week = 1
		week += 1
		change_state(State.DEADLINE)
	emit_signal("race_finished")

func trigger_game_over(reason: String) -> void:
	game_over_reason = reason
	change_state(State.GAME_OVER)

func reset() -> void:
	week = 1
	race_in_week = 1
	cash = 800.0
	debt = 10000.0
	weekly_payment = debt / 8.0
	game_over_reason = ""
	suspicion = 0.0
	current_horses = []
	current_odds = {}
	last_result = []
	last_profit = 0.0
	state = State.MENU

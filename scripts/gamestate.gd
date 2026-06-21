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

var state: State = State.MENU
var week: int = 0
var race_in_week: int = 1
var cash: float = 800.0
var debt: float = 10000.0
var game_over_reason: String = ""

var current_horses: Array = []
var current_odds: Dictionary = {}
var last_result: Array = []
var last_profit: float = 0.0

signal state_changed(new_state: State)
signal cash_changed(new_amount: float)

func change_state(new_state: State) -> void:
	state = new_state
	emit_signal("state_changed", new_state)
	# CORRECTION : changer de scène automatiquement selon l'état
	match new_state:
		State.DEADLINE:
			get_tree().change_scene_to_file("res://scenes/deadline.tscn")
		State.GAME_OVER:
			get_tree().change_scene_to_file("res://scenes/gameover.tscn")

func add_cash(amount: float) -> void:
	cash += amount
	emit_signal("cash_changed", cash)

func get_weekly_payment() -> float:
	return debt / 8.0

func pay_debt() -> bool:
	var payment = get_weekly_payment()
	if cash >= payment:
		cash -= payment
		debt -= payment
		emit_signal("cash_changed", cash)
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

func trigger_game_over(reason: String) -> void:
	game_over_reason = reason
	change_state(State.GAME_OVER)

func reset() -> void:
	week = 1
	race_in_week = 1
	cash = 800.0
	debt = 10000.0
	game_over_reason = ""
	current_horses = []
	current_odds = {}
	last_result = []
	last_profit = 0.0
	state = State.MENU

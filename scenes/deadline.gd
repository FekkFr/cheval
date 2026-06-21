extends Control

@onready var label_amount = $Layout/LabelAmount
@onready var label_cash = $Layout/LabelCash
@onready var btn_pay = $Layout/BtnPay

func _ready():
	var payment = GameState.get_weekly_payment()
	label_amount.text = "TRANCHE DUE : $" + str(int(payment))
	label_cash.text = "TA CAISSE : $" + str(int(GameState.cash))
	# Si pas assez d'argent, on paie quand même → game over automatique
	btn_pay.pressed.connect(_on_pay)

func _on_pay():
	GameState.pay_debt()
	if GameState.state != GameState.State.GAME_OVER:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

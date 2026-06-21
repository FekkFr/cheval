extends Control

@onready var label_reason = $Layout/LabelReason
@onready var label_stats = $Layout/LabelStats
@onready var btn_restart = $Layout/BtnRestart

func _ready():
	match GameState.game_over_reason:
		"debt":
			label_reason.text = "ILS T'ONT TROUVÉ."
		"arrested":
			label_reason.text = "L'INSPECTEUR T'A EU."
	label_stats.text = (
		"Semaines survécues : " + str(GameState.week) + "\n" +
		"Argent au moment de la chute : $" + str(int(GameState.cash))
	)
	btn_restart.pressed.connect(_on_restart)

func _on_restart():
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

extends Control

var shop_mods = []

func _ready():
	$Layout/Label.text = "🎟 " + str(ModifierManager.tickets)
	$Layout/ModsContainer/BtnClose.pressed.connect(_on_close_pressed)
	
	shop_mods = ModifierManager.get_shop_modifiers(3)
	
	var cards = [
		$Layout/ModsContainer/ModsContainer/ModCard1,
		$Layout/ModsContainer/ModsContainer/ModCard2,
		$Layout/ModsContainer/ModsContainer/ModCard3
	]
	
	for i in shop_mods.size():
		var mod = shop_mods[i]
		var card = cards[i]
		card.get_node("LabelIcon").text = mod.icon
		card.get_node("LabelName").text = mod.mod_name
		card.get_node("LabelDesc").text = mod.description
		card.get_node("LabelCost").text = "🎟 " + str(mod.cost)
		card.get_node("BtnBuy").pressed.connect(_on_buy_pressed.bind(i))

func _on_buy_pressed(index: int):
	var mod = shop_mods[index]
	var success = ModifierManager.buy_modifier(mod)
	if success:
		$Layout/Label.text = "🎟 " + str(ModifierManager.tickets)
		print("Acheté : ", mod.mod_name)
	else:
		print("Achat impossible")

func _on_close_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

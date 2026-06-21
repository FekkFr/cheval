extends Control

@onready var label_cash = $Layout/HUDMoney/LabelCash
@onready var label_debt = $Layout/HUDMoney/LabelDebt
@onready var btn_launch = $BtnLaunch
@onready var race_track = $Layout/RaceTrack/OvalTrack
@onready var label_tickets = $Layout/HUD/LabelTickets
@onready var btn_shop = $Layout/HUD/BtnShop
@onready var label_payment = $Layout/HUD/LabelPayment
@onready var bars = [
	$Layout/RaceBar/ProgressBar1,
	$Layout/RaceBar/ProgressBar2,
	$Layout/RaceBar/ProgressBar3,
	$Layout/RaceBar/ProgressBar4
]
@onready var horse_names = [
	$HorsesContainer/HorseCard1/LabelName,
	$HorsesContainer/HorseCard2/LabelName,
	$HorsesContainer/HorseCard3/LabelName,
	$HorsesContainer/HorseCard4/LabelName
]
@onready var horse_stats = [
	$HorsesContainer/HorseCard1/LabelStat,
	$HorsesContainer/HorseCard2/LabelStat,
	$HorsesContainer/HorseCard3/LabelStat,
	$HorsesContainer/HorseCard4/LabelStat
]
@onready var sliders = [
	$HorsesContainer/HorseCard1/HSlider,
	$HorsesContainer/HorseCard2/HSlider,
	$HorsesContainer/HorseCard3/HSlider,
	$HorsesContainer/HorseCard4/HSlider
]
@onready var odds_labels = [
	$HorsesContainer/HorseCard1/LabelOdds,
	$HorsesContainer/HorseCard2/LabelOdds,
	$HorsesContainer/HorseCard3/LabelOdds,
	$HorsesContainer/HorseCard4/LabelOdds
]
@onready var target_buttons = [
	$HorsesContainer/HorseCard1/BtnTarget,
	$HorsesContainer/HorseCard2/BtnTarget,
	$HorsesContainer/HorseCard3/BtnTarget,
	$HorsesContainer/HorseCard4/BtnTarget
]
@onready var bet_inputs = [
	$HorsesContainer/HorseCard1/SpinBox,
	$HorsesContainer/HorseCard2/SpinBox,
	$HorsesContainer/HorseCard3/SpinBox,
	$HorsesContainer/HorseCard4/SpinBox
]

var resolver = RaceResolver.new()
var bookmaker = Bookmaker.new()
var current_odds = {}
var race_running = false
var waiting_for_target: ModifierBase = null

func _style_horse_names():
	var font = load("res://fonts/BebasNeue-Regular.ttf")
	if font:
		for label in horse_names:
			label.add_theme_font_override("font", font)
			label.add_theme_font_size_override("font_size", 22)
			label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
			label.add_theme_constant_override("shadow_offset_x", 2)
			label.add_theme_constant_override("shadow_offset_y", 2)
func _style_launch_button():
	var font = load("res://fonts/BebasNeue-Regular.ttf")
	if font:
		btn_launch.add_theme_font_override("font", font)
		btn_launch.add_theme_font_size_override("font_size", 50)
		btn_launch.add_theme_color_override("font_color", Color("020100ff"))
	var transparent = StyleBoxEmpty.new()
	btn_launch.add_theme_stylebox_override("normal", transparent)
	btn_launch.add_theme_stylebox_override("hover", transparent)
	btn_launch.add_theme_stylebox_override("pressed", transparent)
	btn_launch.add_theme_stylebox_override("hover_pressed", transparent)
	btn_launch.add_theme_stylebox_override("focus", transparent)
	btn_launch.add_theme_stylebox_override("disabled", transparent)

func _ready():
	print("DEBUT _ready")
	for i in target_buttons.size():
		target_buttons[i].pressed.connect(_on_horse_targeted.bind(i))
		target_buttons[i].visible = false
		target_buttons[i].disabled = true
	for input in bet_inputs:
		input.visible = false
	_new_race()
	print("Après _new_race")
	GameState.cash_changed.connect(_on_cash_changed)
	btn_launch.pressed.connect(_on_launch_pressed)
	print("BOUTON CONNECTÉ")
	btn_shop.pressed.connect(_on_shop_pressed)
	ModifierManager.tickets_changed.connect(_on_tickets_changed)
	ModifierManager.modifier_activated.connect(_on_modifier_activated)
	for i in sliders.size():
		sliders[i].value_changed.connect(_on_slider_changed.bind(i))
	for slider in sliders:
		slider.custom_minimum_size = Vector2(150, 20)
	print("FIN _ready")
	_style_launch_button()
	_style_horse_names()

func _on_shop_pressed():
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _enable_horse_targeting(enabled: bool) -> void:
	for i in target_buttons.size():
		target_buttons[i].visible = enabled
		target_buttons[i].disabled = !enabled
		target_buttons[i].custom_minimum_size = Vector2(100, 40)
		target_buttons[i].text = "🎯 CIBLER"
	btn_launch.disabled = enabled

func _on_horse_targeted(index: int) -> void:
	if waiting_for_target == null: return
	waiting_for_target.target_index = index
	var horse = GameState.current_horses[index]
	print("[CIBLAGE] ", waiting_for_target.mod_name, " → ", horse.horse_name)
	waiting_for_target = null
	_enable_horse_targeting(false)

func _on_modifier_activated(mod: ModifierBase):
	if mod.needs_target:
		waiting_for_target = mod
		_enable_horse_targeting(true)
		print("Cliquez sur un cheval à cibler")

func _check_pending_targets():
	for mod in ModifierManager.active_modifiers:
		if mod.needs_target and mod.target_index == -1:
			waiting_for_target = mod
			_enable_horse_targeting(true)
			break
	var pari_actif = false
	for mod in ModifierManager.active_modifiers:
		if mod.mod_id == "mod_pari_perso":
			pari_actif = true
			break
	for input in bet_inputs:
		input.visible = pari_actif

func _new_race():
	GameState.current_horses = RaceResolver.generate_field()
	current_odds = bookmaker.suggest_odds(GameState.current_horses)
	GameState.current_odds = current_odds
	for i in GameState.current_horses.size():
		var horse = GameState.current_horses[i]
		sliders[i].min_value = 1.1
		sliders[i].max_value = 5.0
		sliders[i].step = 0.2
		sliders[i].value = 1.0
		current_odds[horse.horse_name] = 1.0
		odds_labels[i].text = "1.0×"
	_refresh_hud()
	_refresh_horses()
	for bar in bars:
		bar.value = 0
	_check_pending_targets()
	for input in bet_inputs:
		input.max_value = GameState.cash * 0.3
		input.step = 10
	for pf in race_track.path_follows:
		pf.progress_ratio = 0.0

func _refresh_hud():
	label_cash.text = "CAISSE : $" + str(int(GameState.cash))
	label_debt.text = "DETTE : $" + str(int(GameState.debt))
	label_payment.text = "TRANCHE : $" + str(int(GameState.get_weekly_payment()))
	label_tickets.text = "🎟 " + str(ModifierManager.tickets)

func _on_cash_changed(amount):
	label_cash.text = "CAISSE : $" + str(int(amount))

func _on_tickets_changed(amount: int):
	label_tickets.text = "🎟 " + str(amount)

func _refresh_horses():
	var colors = {
		"FAVORI": Color("5fd35f"),
		"SOLIDE": Color("7ab8e0"),
		"MOYEN": Color("e0c060"),
		"OUTSIDER": Color("#e05f5f")
	}

	for i in GameState.current_horses.size():
		var horse = GameState.current_horses[i]
		var avg = (horse.form + horse.stamina + horse.track_fit) / 3.0
		horse_stats[i].visible = false
		var level = ""
		if avg >= 75:
			level = "FAVORI"
		elif avg >= 55:
			level = "SOLIDE"
		elif avg >= 40:
			level = "MOYEN"
		else:
			level = "OUTSIDER"

		# Le nom prend la couleur du niveau, plus de label texte séparé
		horse_names[i].text = horse.horse_name
		horse_names[i].add_theme_color_override("font_color", colors[level])

func _on_slider_changed(value: float, index: int):
	print("Slider ", index, " changé : ", value)
	var horse = GameState.current_horses[index]
	current_odds[horse.horse_name] = value
	odds_labels[index].text = str(snappedf(value, 0.1)) + "×"

func _on_launch_pressed():
	print("CLIC DÉTECTÉ SUR LANCER")
	if race_running: return
	race_running = true
	btn_launch.disabled = true

	ModifierManager.apply_before_race(GameState.current_horses)
	GameState.last_result = resolver.resolve(GameState.current_horses)
	await _animate_race()

	var winner = GameState.last_result[0]
	var bets = bookmaker.calculate_bets(current_odds)
	var profit = bookmaker.calculate_profit(winner.horse_name, current_odds, bets)
	GameState.add_cash(profit)

	# Pari personnel AVANT tick_all
	var pari_actif = false
	for mod in ModifierManager.active_modifiers:
		if mod.mod_id == "mod_pari_perso":
			pari_actif = true
			break
	print("Pari actif : ", pari_actif)
	for i in GameState.current_horses.size():
		print("Mise ", i, " : ", bet_inputs[i].value)
	if pari_actif:
		for i in GameState.current_horses.size():
			var horse = GameState.current_horses[i]
			var mise = bet_inputs[i].value
			if mise > 0:
				if horse.horse_name == winner.horse_name:
					var gain = mise * current_odds[horse.horse_name]
					GameState.add_cash(gain - mise)
					print("[PARI] Gagné : +$", int(gain - mise))
				else:
					GameState.add_cash(-mise)
					print("[PARI] Perdu : -$", int(mise))
		for input in bet_inputs:
			input.value = 0

	ModifierManager.earn_tickets(profit)
	ModifierManager.tick_all()

	await _show_result(winner, profit)

	GameState.next_race()
	if GameState.state == GameState.State.BRIEFING:
		_new_race()
	race_running = false
	btn_launch.disabled = false


func _animate_race():
	var horses = GameState.current_horses
	var scores = []
	for horse in horses:
		scores.append(horse.final_score)
	await race_track.animate_race(scores)

func _show_result(winner: Horse, profit: float):
	var popup = Label.new()
	add_child(popup)
	var podium_text = "═══ RÉSULTAT ═══\n"
	for i in GameState.last_result.size():
		var medals = ["🥇", "🥈", "🥉", "4️⃣"]
		podium_text += medals[i] + " " + GameState.last_result[i].horse_name + "\n"
	podium_text += "════════════════\n"
	if profit >= 0:
		podium_text += "PROFIT : +$" + str(int(profit))
	else:
		podium_text += "PERTE : -$" + str(int(abs(profit)))
	popup.text = podium_text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 24)
	popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	popup.size = Vector2(400, 250)
	popup.position = Vector2(get_viewport_rect().size / 2) - popup.size / 2
	await get_tree().create_timer(3.0).timeout
	popup.queue_free()

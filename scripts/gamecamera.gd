extends Node3D

@onready var camera = $Camera3D
@onready var main_ui = $CanvasLayer/Main
@onready var btn_back = $CanvasLayer/BtnBack
@onready var click_area = $Carte/Cube/ClickArea
@onready var label_cash_world = $CanvasLayer/PanelMoney/VBoxMoney/LabelCashWorld
@onready var label_tranche_world = $CanvasLayer/PanelMoney/VBoxMoney/LabelTrancheWorld
@onready var panel_money = $CanvasLayer/PanelMoney
@onready var pion_bg = $CanvasLayer/PionBg
@onready var pion_popup = $CanvasLayer/PionPopup
@onready var btn_cancel = $CanvasLayer/PionPopup/BtnCancel
@onready var pion_label = $CanvasLayer/PionPopup/LabelHorseName
@onready var btn_confirm = $CanvasLayer/PionPopup/BtnConfirm
@onready var pions = [
	$Room/Pions/pion1,
	$Room/Pions/pion2,
	$Room/Pions/pion3,
	$Room/Pions/pion4
]

var _pion_original_positions = []
var _pending_pion = null
var zoomed_in = false
var default_cam_pos: Vector3
var default_cam_rot: Vector3
var _pending_target_index = -1
var zoom_cam_pos = Vector3(0.226, 3.848, 0.0)
var zoom_cam_rot = Vector3(deg_to_rad(-1.7), deg_to_rad(-90.0), deg_to_rad(0.0))

func _style_launch_button():
	var font = load("res://fonts/BebasNeue-Regular.ttf")
	var transparent = StyleBoxEmpty.new()
	
	for btn in [btn_confirm, btn_cancel]:
		if font:
			btn.add_theme_font_override("font", font)
			btn.add_theme_font_size_override("font_size", 50)
			btn.add_theme_color_override("font_color", Color("736546ff"))
		btn.add_theme_stylebox_override("normal", transparent)
		btn.add_theme_stylebox_override("hover", transparent)
		btn.add_theme_stylebox_override("pressed", transparent)
		btn.add_theme_stylebox_override("hover_pressed", transparent)
		btn.add_theme_stylebox_override("focus", transparent)
		btn.add_theme_stylebox_override("disabled", transparent)
	if font:
		pion_label.add_theme_font_override("font", font)
		pion_label.add_theme_font_size_override("font_size", 72)
		pion_label.add_theme_color_override("font_color", Color("#e8d5b0"))
		pion_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		pion_label.add_theme_constant_override("shadow_offset_x", 3)
		pion_label.add_theme_constant_override("shadow_offset_y", 3)
		btn_confirm.add_theme_color_override("font_color_disabled", Color("#736546ff"))

func _refresh_hud_world():
	label_cash_world.text = "CAISSE : $" + str(int(GameState.cash))
	label_tranche_world.text = "TRANCHE : $" + str(int(GameState.get_weekly_payment()))

func _on_cash_changed_world(amount):
	label_cash_world.text = "CAISSE : $" + str(int(amount))

func _style_money_badges():
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.04, 0.03, 0.02, 0.85)
	badge_style.corner_radius_top_left = 8
	badge_style.corner_radius_top_right = 8
	badge_style.corner_radius_bottom_left = 8
	badge_style.corner_radius_bottom_right = 8
	badge_style.content_margin_left = 24
	badge_style.content_margin_right = 24
	badge_style.content_margin_top = 14
	badge_style.content_margin_bottom = 14
	panel_money.add_theme_stylebox_override("panel", badge_style)
	var font = load("res://fonts/SpecialElite.ttf")
	for label in [label_cash_world, label_tranche_world]:
		if font:
			label.add_theme_font_override("font", font)
			label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color("#e8d5b0"))

func _ready():
	default_cam_pos = camera.position
	default_cam_rot = camera.rotation
	click_area.input_event.connect(_on_carte_clicked)
	btn_back.pressed.connect(_on_back_pressed)
	btn_back.visible = false
	main_ui.visible = false
	_set_ui_interactive(false)
	GameState.cash_changed.connect(_on_cash_changed_world)
	_refresh_hud_world()
	_style_money_badges()
	for i in pions.size():
		var area = pions[i].get_node("ClickArea")
		area.input_event.connect(_on_pion_clicked.bind(i))
	for pion in pions:
		_pion_original_positions.append(pion.position)
	btn_confirm.pressed.connect(_on_confirm_target)
	btn_cancel.pressed.connect(_on_cancel_target)
	_style_launch_button()

func _set_emission(pion_node, enabled: bool):
	var mesh_names = ["Circle", "Circle_001", "Icosphere"]
	for mesh_name in mesh_names:
		var mesh = pion_node.get_node(mesh_name)
		for surface_idx in mesh.get_surface_override_material_count():
			var mat = mesh.get_active_material(surface_idx)
			if mat:
				mat = mat.duplicate()
				mat.emission_enabled = enabled
				if enabled:
					mat.emission = Color("#e8d5b0")
					mat.emission_energy_multiplier = 0.8  # réduit, moins fort
				mesh.set_surface_override_material(surface_idx, mat)

func _on_cancel_target():
	var original_pos = _pion_original_positions[_pending_target_index]
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pending_pion, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_pending_pion, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_pending_pion, "rotation:y", 0.0, 0.3)

	_set_emission(_pending_pion, false)

	var tween_bg = create_tween()
	tween_bg.tween_property(pion_bg, "color:a", 0.0, 0.3)
	await tween_bg.finished
	pion_bg.visible = false
	pion_popup.visible = false

	_pending_target_index = -1
	_pending_pion = null

func _on_pion_clicked(cam, event, position, normal, shape_idx, index: int):
	if not event is InputEventMouseButton or not event.pressed:
		return

	var horse = GameState.current_horses[index]
	_pending_target_index = index
	_pending_pion = pions[index]

	var target_pos = Vector3(
		camera.global_position.x + 1.8,
		camera.global_position.y - 1,
		camera.global_position.z
	)

	# Activer l'émission AVANT le tween pour qu'elle apparaisse dès le début
	_set_emission(_pending_pion, true)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pending_pion, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_pending_pion, "scale", Vector3(2.5, 2.5, 2.5), 0.4).set_trans(Tween.TRANS_CUBIC)

	pion_bg.visible = true
	var tween_bg = create_tween()
	tween_bg.tween_property(pion_bg, "color:a", 0.35, 0.3)
	await tween.finished

	pion_label.text = horse.horse_name
	pion_popup.visible = true
	btn_confirm.visible = true
	btn_confirm.disabled = main_ui.waiting_for_target == null

func _on_carte_clicked(cam_param, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and not zoomed_in:
		_zoom_to_carte()

func _process(delta):
	label_tranche_world.text = "TRANCHE : $" + str(int(GameState.get_weekly_payment()))
	if _pending_pion != null:
		var rot = _pending_pion.rotation
		rot.y += delta * 0.8
		_pending_pion.rotation = rot

func _zoom_to_carte():
	zoomed_in = true
	_set_ui_interactive(false)
	main_ui.visible = false

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "position", zoom_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "rotation", zoom_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	main_ui.scale = Vector2(0.7, 0.7)
	main_ui.position = Vector2(250, 100)
	main_ui.visible = true
	_set_ui_interactive(true)
	btn_back.visible = true

func _on_back_pressed():
	zoomed_in = false
	btn_back.visible = false
	_set_ui_interactive(false)
	main_ui.visible = false

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "position", default_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "rotation", default_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	main_ui.scale = Vector2(0.3, 0.3)
	main_ui.position = Vector2(412.74, 100.0)

func _set_ui_interactive(active: bool):
	main_ui.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE

func _on_confirm_target():
	if _pending_target_index == -1 or _pending_pion == null:
		return

	main_ui._on_horse_targeted(_pending_target_index)

	var pion_to_reset = _pending_pion  # garde la ref avant de la nullifier
	var original_pos = _pion_original_positions[_pending_target_index]

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pion_to_reset, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(pion_to_reset, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(pion_to_reset, "rotation:y", 0.0, 0.3)

	_set_emission(pion_to_reset, false)

	var tween_bg = create_tween()
	tween_bg.tween_property(pion_bg, "color:a", 0.0, 0.3)
	await tween_bg.finished
	pion_bg.visible = false
	pion_popup.visible = false

	_pending_target_index = -1
	_pending_pion = null

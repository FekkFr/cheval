extends Node3D

@onready var btn_shop = $CanvasLayer/BtnShop
@onready var btn_back_shop = $CanvasLayer/BtnBackShop
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
@onready var emplacements = [
	$Room/Boutique/Emplacement1,
	$Room/Boutique/Emplacement2,
	$Room/Boutique/Emplacement3
]

var _shop_modifiers = []
var shop_cam_rot = Vector3(deg_to_rad(-11.3), deg_to_rad(90.0), deg_to_rad(0.0))
var in_shop = false
var _pion_original_positions = []
var _pending_pion = null
var zoomed_in = false
var default_cam_pos: Vector3
var default_cam_rot: Vector3
var _pending_target_index = -1
var zoom_cam_pos = Vector3(0.226, 3.848, 0.0)
var zoom_cam_rot = Vector3(deg_to_rad(-1.7), deg_to_rad(-90.0), deg_to_rad(0.0))
var _boite_names = {
	"mod_sabotage": "sabotage",
	"mod_stimulant": "stimulant",
	"mod_rumeur": "rumeur",
	"mod_pari_perso": "paris"
}
var _pending_shop_index = -1
var _pending_shop_node = null
var _shop_original_positions = []

# ── Styles ────────────────────────────────────────
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

# ── HUD ───────────────────────────────────────────
func _refresh_hud_world():
	label_cash_world.text = "CAISSE : $" + str(int(GameState.cash))
	label_tranche_world.text = "TRANCHE : $" + str(int(GameState.get_weekly_payment()))

func _on_cash_changed_world(amount):
	label_cash_world.text = "CAISSE : $" + str(int(amount))

# ── Boutique ──────────────────────────────────────
func _refresh_shop():
	_shop_modifiers = ModifierManager.get_shop_modifiers(3)
	for i in emplacements.size():
		var emplacement = emplacements[i]
		for boite_name in _boite_names.values():
			var boite = emplacement.get_node_or_null(boite_name)
			if boite:
				boite.visible = false
		if i < _shop_modifiers.size():
			var mod = _shop_modifiers[i]
			var boite_name = _boite_names.get(mod.mod_id, "")
			if boite_name != "":
				var boite = emplacement.get_node_or_null(boite_name)
				if boite:
					boite.visible = true

func _zoom_to_shop():
	in_shop = true
	btn_shop.visible = false
	btn_back_shop.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "position", default_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "rotation", shop_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

func _zoom_back_from_shop():
	in_shop = false
	btn_back_shop.visible = false
	btn_shop.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "position", default_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "rotation", default_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

func _on_shop_clicked(cam, event, position, normal, shape_idx, index: int):
	if not event is InputEventMouseButton or not event.pressed:
		return
	if not in_shop:
		return
	if index >= _shop_modifiers.size():
		return

	var mod = _shop_modifiers[index]
	_pending_shop_index = index
	_pending_shop_node = emplacements[index]

	var target_pos = Vector3(
		camera.global_position.x - 1.8,
		camera.global_position.y - 1,
		camera.global_position.z
	)

	# Activer l'émission sur la boite visible (cherche le bon node directement)
	var boite_name = _boite_names.get(mod.mod_id, "")
	if boite_name != "":
		var boite = _pending_shop_node.get_node_or_null(boite_name)
		if boite:
			_set_emission_boite(boite, true)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pending_shop_node, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_pending_shop_node, "scale", Vector3(2.5, 2.5, 2.5), 0.4).set_trans(Tween.TRANS_CUBIC)

	pion_bg.visible = true
	var tween_bg = create_tween()
	tween_bg.tween_property(pion_bg, "color:a", 0.35, 0.3)
	await tween.finished

	pion_label.text = mod.mod_name
	btn_confirm.visible = true
	btn_confirm.disabled = ModifierManager.tickets < mod.cost
	pion_popup.visible = true

func _on_confirm_shop():
	if _pending_shop_index == -1 or _pending_shop_node == null:
		return

	var mod = _shop_modifiers[_pending_shop_index]
	ModifierManager.buy_modifier(mod)

	var shop_node_to_reset = _pending_shop_node
	var original_pos = _shop_original_positions[_pending_shop_index]

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(shop_node_to_reset, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(shop_node_to_reset, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)

	var boite_name = _boite_names.get(mod.mod_id, "")
	if boite_name != "":
		var boite = shop_node_to_reset.get_node_or_null(boite_name)
		if boite:
			_set_emission_boite(boite, false)

	var tween_bg = create_tween()
	tween_bg.tween_property(pion_bg, "color:a", 0.0, 0.3)
	await tween_bg.finished
	pion_bg.visible = false
	pion_popup.visible = false

	_pending_shop_index = -1
	_pending_shop_node = null

# ── Émission pions (Circle/Circle_001/Icosphere) ──
func _set_emission(pion_node, enabled: bool):
	var mesh_names = ["Circle", "Circle_001", "Icosphere"]
	for mesh_name in mesh_names:
		var mesh = pion_node.get_node_or_null(mesh_name)
		if mesh == null:
			continue
		for surface_idx in mesh.get_surface_override_material_count():
			var mat = mesh.get_active_material(surface_idx)
			if mat:
				mat = mat.duplicate()
				mat.emission_enabled = enabled
				if enabled:
					mat.emission = Color("#e8d5b0")
					mat.emission_energy_multiplier = 0.8
				mesh.set_surface_override_material(surface_idx, mat)

func _set_emission_boite(boite_node, enabled: bool):
	# Parcourt tous les enfants pour trouver les MeshInstance3D
	for child in boite_node.get_children():
		if child is MeshInstance3D:
			for surface_idx in child.get_surface_override_material_count():
				var mat = child.get_active_material(surface_idx)
				if mat:
					mat = mat.duplicate()
					mat.emission_enabled = enabled
					if enabled:
						mat.emission = Color("#e8d5b0")
						mat.emission_energy_multiplier = 0.8
					child.set_surface_override_material(surface_idx, mat)

# ── Pions ─────────────────────────────────────────
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

func _on_cancel_target():
	# Annule soit un pion soit une boite boutique
	if _pending_pion != null:
		var original_pos = _pion_original_positions[_pending_target_index]
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_pending_pion, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_pending_pion, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_pending_pion, "rotation:y", 0.0, 0.3)
		_set_emission(_pending_pion, false)
		_pending_target_index = -1
		_pending_pion = null
	elif _pending_shop_node != null:
		var original_pos = _shop_original_positions[_pending_shop_index]
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_pending_shop_node, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_pending_shop_node, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)
		var boite_name = _boite_names.get(_shop_modifiers[_pending_shop_index].mod_id, "")
		if boite_name != "":
			var boite = _pending_shop_node.get_node_or_null(boite_name)
			if boite:
				_set_emission_boite(boite, false)
			await tween.finished 
		_pending_shop_index = -1
		_pending_shop_node = null

	var tween_bg = create_tween()
	tween_bg.tween_property(pion_bg, "color:a", 0.0, 0.3)
	await tween_bg.finished
	pion_bg.visible = false
	pion_popup.visible = false

func _on_confirm_pressed():
	if _pending_shop_index != -1:
		_on_confirm_shop()
	elif _pending_target_index != -1:
		_on_confirm_target()

func _on_confirm_target():
	if _pending_target_index == -1 or _pending_pion == null:
		return

	main_ui._on_horse_targeted(_pending_target_index)

	var pion_to_reset = _pending_pion
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

# ── Caméra ────────────────────────────────────────
func _on_carte_clicked(cam_param, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and not zoomed_in:
		_zoom_to_carte()

func _zoom_to_carte():
	zoomed_in = true
	btn_shop.visible = false
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
	btn_shop.visible = true
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

func _process(delta):
	label_tranche_world.text = "TRANCHE : $" + str(int(GameState.get_weekly_payment()))
	if _pending_pion != null:
		var rot = _pending_pion.rotation
		rot.y += delta * 0.8
		_pending_pion.rotation = rot

# ── Ready ─────────────────────────────────────────
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
	_style_launch_button()

	for i in pions.size():
		var area = pions[i].get_node("ClickArea")
		area.input_event.connect(_on_pion_clicked.bind(i))
	for pion in pions:
		_pion_original_positions.append(pion.position)

	btn_confirm.pressed.connect(_on_confirm_pressed)  # une seule connexion
	btn_cancel.pressed.connect(_on_cancel_target)

	btn_shop.pressed.connect(_zoom_to_shop)
	btn_back_shop.pressed.connect(_zoom_back_from_shop)
	btn_back_shop.visible = false
	_refresh_shop()

	for i in emplacements.size():
		var area = emplacements[i].get_node("ClickArea")
		area.input_event.connect(_on_shop_clicked.bind(i))
	for emplacement in emplacements:
		_shop_original_positions.append(emplacement.position)

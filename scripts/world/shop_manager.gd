extends Node
class_name ShopManager

signal item_selection_started(mod: ModifierBase)
signal item_selection_cancelled
signal purchase_confirmed

var in_shop: bool = false

var _camera: Camera3D
var _btn_shop: Button
var _btn_back_shop: Button
var _pion_bg: ColorRect
var _emplacements: Array
var _boite_names: Dictionary
var _shop_original_positions: Array = []
var _shop_modifiers: Array = []
var _shop_cam_rot := Vector3(deg_to_rad(-11.3), deg_to_rad(90.0), deg_to_rad(0.0))
var _default_cam_pos: Vector3
var _default_cam_rot: Vector3

var _pending_index: int = -1
var _pending_node: Node3D = null

func setup(camera: Camera3D, btn_shop: Button, btn_back_shop: Button, pion_bg: ColorRect, emplacements: Array, boite_names: Dictionary, default_cam_pos: Vector3, default_cam_rot: Vector3) -> void:
	_camera = camera
	_btn_shop = btn_shop
	_btn_back_shop = btn_back_shop
	_pion_bg = pion_bg
	_emplacements = emplacements
	_boite_names = boite_names
	_default_cam_pos = default_cam_pos
	_default_cam_rot = default_cam_rot

	for emplacement in _emplacements:
		_shop_original_positions.append(emplacement.position)

	_btn_shop.pressed.connect(zoom_to_shop)
	_btn_back_shop.pressed.connect(zoom_back_from_shop)
	_btn_back_shop.visible = false

	for i in _emplacements.size():
		var area = _emplacements[i].get_node("ClickArea")
		area.input_event.connect(_on_clicked.bind(i))

	GameState.race_finished.connect(refresh_shop)
	refresh_shop()

func has_pending() -> bool:
	return _pending_index != -1

func zoom_to_shop() -> void:
	in_shop = true
	_btn_shop.visible = false
	_btn_back_shop.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_camera, "position", _default_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_camera, "rotation", _shop_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

func zoom_back_from_shop() -> void:
	in_shop = false
	_btn_back_shop.visible = false
	_btn_shop.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_camera, "position", _default_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_camera, "rotation", _default_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

func refresh_shop() -> void:
	_shop_modifiers = ModifierManager.get_shop_modifiers(3)
	for i in _emplacements.size():
		var emplacement = _emplacements[i]
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

func _on_clicked(_cam, event, _position, _normal, _shape_idx, index: int) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if not in_shop:
		return
	if index >= _shop_modifiers.size():
		return

	var mod = _shop_modifiers[index]
	_pending_index = index
	_pending_node = _emplacements[index]
	_btn_back_shop.visible = false

	var target_pos = Vector3(
		_camera.global_position.x - 1.8,
		_camera.global_position.y - 1,
		_camera.global_position.z
	)

	var boite_name = _boite_names.get(mod.mod_id, "")
	if boite_name != "":
		var boite = _pending_node.get_node_or_null(boite_name)
		if boite:
			_set_emission_boite(boite, true)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pending_node, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_pending_node, "scale", Vector3(2.5, 2.5, 2.5), 0.4).set_trans(Tween.TRANS_CUBIC)

	_pion_bg.visible = true
	var tween_bg = create_tween()
	tween_bg.tween_property(_pion_bg, "color:a", 0.35, 0.3)
	await tween.finished

	item_selection_started.emit(mod)

func confirm_purchase() -> void:
	if _pending_index == -1 or _pending_node == null:
		return

	var mod = _shop_modifiers[_pending_index]
	ModifierManager.buy_modifier(mod)

	var shop_node_to_reset = _pending_node
	var original_pos = _shop_original_positions[_pending_index]

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(shop_node_to_reset, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(shop_node_to_reset, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)

	var boite_name = _boite_names.get(mod.mod_id, "")
	if boite_name != "":
		var boite = shop_node_to_reset.get_node_or_null(boite_name)
		if boite:
			_set_emission_boite(boite, false)

	_pending_index = -1
	_pending_node = null
	purchase_confirmed.emit()

func cancel_selection() -> void:
	if _pending_node == null:
		return

	var original_pos = _shop_original_positions[_pending_index]
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pending_node, "position", original_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_pending_node, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)

	var boite_name = _boite_names.get(_shop_modifiers[_pending_index].mod_id, "")
	if boite_name != "":
		var boite = _pending_node.get_node_or_null(boite_name)
		if boite:
			_set_emission_boite(boite, false)
		await tween.finished

	_pending_index = -1
	_pending_node = null
	item_selection_cancelled.emit()

func _set_emission_boite(boite_node, enabled: bool) -> void:
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

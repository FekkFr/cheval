extends Node
class_name PionManager

signal selection_started(horse: Horse)
signal target_confirmed
signal selection_cancelled

var _camera: Camera3D
var _pion_bg: ColorRect
var _pions: Array
var _pion_original_positions: Array = []
var _main_ui
var _btn_shop: Button
var _btn_back_shop: Button

var _pending_index: int = -1
var _pending_pion: Node3D = null

func setup(camera: Camera3D, pion_bg: ColorRect, pions: Array, main_ui, btn_shop: Button, btn_back_shop: Button) -> void:
	_camera = camera
	_pion_bg = pion_bg
	_pions = pions
	_main_ui = main_ui
	_btn_shop = btn_shop
	_btn_back_shop = btn_back_shop

	for pion in _pions:
		_pion_original_positions.append(pion.position)
	for i in _pions.size():
		var area = _pions[i].get_node("ClickArea")
		area.input_event.connect(_on_clicked.bind(i))

func has_pending() -> bool:
	return _pending_index != -1

func get_pending_index() -> int:
	return _pending_index

func _on_clicked(_cam, event, _position, _normal, _shape_idx, index: int) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	var horse = GameState.current_horses[index]
	_pending_index = index
	_pending_pion = _pions[index]
	# On cache immédiatement les boutons de navigation (pas d'attente du tween)
	_btn_shop.visible = false
	_btn_back_shop.visible = false

	var target_pos = Vector3(
		_camera.global_position.x + 1.8,
		_camera.global_position.y - 1,
		_camera.global_position.z
	)

	_set_emission(_pending_pion, true)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pending_pion, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_pending_pion, "scale", Vector3(2.5, 2.5, 2.5), 0.4).set_trans(Tween.TRANS_CUBIC)

	_pion_bg.visible = true
	var tween_bg = create_tween()
	tween_bg.tween_property(_pion_bg, "color:a", 0.35, 0.3)
	await tween.finished

	selection_started.emit(horse)

func confirm_target() -> void:
	if _pending_index == -1 or _pending_pion == null:
		return
	_main_ui._on_horse_targeted(_pending_index)
	_reset_pion()
	target_confirmed.emit()

func cancel_selection() -> void:
	if _pending_pion == null:
		return
	_reset_pion()
	selection_cancelled.emit()

func _reset_pion() -> void:
	var pion_to_reset = _pending_pion
	var original_pos = _pion_original_positions[_pending_index]

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pion_to_reset, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(pion_to_reset, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(pion_to_reset, "rotation:y", 0.0, 0.3)
	_set_emission(pion_to_reset, false)

	_pending_index = -1
	_pending_pion = null

func process_rotation(delta: float) -> void:
	if _pending_pion != null:
		var rot = _pending_pion.rotation
		rot.y += delta * 0.8
		_pending_pion.rotation = rot

func _set_emission(pion_node, enabled: bool) -> void:
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

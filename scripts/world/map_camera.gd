extends Node
class_name MapCameraController

var zoomed_in_state: bool = false

var _camera: Camera3D
var _main_ui: Control
var _btn_back: Button
var _btn_shop: Button
var _default_cam_pos: Vector3
var _default_cam_rot: Vector3
var _zoom_cam_pos := Vector3(0.226, 3.848, 0.0)
var _zoom_cam_rot := Vector3(deg_to_rad(-1.7), deg_to_rad(-90.0), deg_to_rad(0.0))

func setup(camera: Camera3D, main_ui: Control, btn_back: Button, btn_shop: Button, default_cam_pos: Vector3, default_cam_rot: Vector3) -> void:
	_camera = camera
	_main_ui = main_ui
	_btn_back = btn_back
	_btn_shop = btn_shop
	_default_cam_pos = default_cam_pos
	_default_cam_rot = default_cam_rot
	_btn_back.pressed.connect(zoom_out)
	_btn_back.visible = false
	_main_ui.visible = false
	_set_ui_interactive(false)

func on_carte_clicked(_cam, event, _position, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and not zoomed_in_state:
		zoom_in()

func zoom_in() -> void:
	zoomed_in_state = true
	_btn_shop.visible = false
	_set_ui_interactive(false)
	_main_ui.visible = false
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_camera, "position", _zoom_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_camera, "rotation", _zoom_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	_main_ui.scale = Vector2(0.7, 0.7)
	_main_ui.position = Vector2(250, 100)
	_main_ui.visible = true
	_set_ui_interactive(true)
	_btn_back.visible = true

func zoom_out() -> void:
	zoomed_in_state = false
	_btn_shop.visible = true
	_btn_back.visible = false
	_set_ui_interactive(false)
	_main_ui.visible = false
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_camera, "position", _default_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_camera, "rotation", _default_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	_main_ui.scale = Vector2(0.3, 0.3)
	_main_ui.position = Vector2(412.74, 100.0)

func _set_ui_interactive(active: bool) -> void:
	_main_ui.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE

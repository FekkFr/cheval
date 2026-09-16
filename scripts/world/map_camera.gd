extends Node
class_name MapCameraController
## Gère la transition entre la pièce (RoomView : bouton carte + bureau +
## boutique) et l'écran de la carte de paris (Main / race_track). En 3D
## c'était un zoom de caméra ; en 2D c'est un simple fondu + léger scale
## entre les deux vues, plus simple à régler.
## NB : on cache toute la pièce (`RoomView`), pas juste le bureau, sinon le
## bouton "Carte des paris" reste visible par-dessus l'écran de course.

var zoomed_in_state: bool = false

var _room_view: Control
var _main_ui: Control
var _btn_back: Button
var _btn_shop: Button

func setup(room_view: Control, main_ui: Control, btn_back: Button, btn_shop: Button) -> void:
	_room_view = room_view
	_main_ui = main_ui
	_btn_back = btn_back
	_btn_shop = btn_shop
	_btn_back.pressed.connect(zoom_out)
	_btn_back.visible = false
	_main_ui.visible = false
	_set_ui_interactive(false)

func zoom_in() -> void:
	if zoomed_in_state:
		return
	zoomed_in_state = true
	_btn_shop.visible = false
	_set_ui_interactive(false)

	var tween_out = create_tween()
	tween_out.tween_property(_room_view, "modulate:a", 0.0, 0.25)
	await tween_out.finished
	_room_view.visible = false

	_main_ui.modulate.a = 0.0
	_main_ui.scale = Vector2(0.94, 0.94)
	_main_ui.pivot_offset = _main_ui.size / 2.0
	_main_ui.visible = true
	var tween_in = create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(_main_ui, "modulate:a", 1.0, 0.3)
	tween_in.tween_property(_main_ui, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC)
	await tween_in.finished
	_set_ui_interactive(true)
	_btn_back.visible = true

func zoom_out() -> void:
	zoomed_in_state = false
	_btn_back.visible = false
	_set_ui_interactive(false)

	var tween_out = create_tween()
	tween_out.tween_property(_main_ui, "modulate:a", 0.0, 0.25)
	await tween_out.finished
	_main_ui.visible = false

	_room_view.visible = true
	_room_view.modulate.a = 0.0
	var tween_in = create_tween()
	tween_in.tween_property(_room_view, "modulate:a", 1.0, 0.25)
	await tween_in.finished
	_btn_shop.visible = true

func _set_ui_interactive(active: bool) -> void:
	_main_ui.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE

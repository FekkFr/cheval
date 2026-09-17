extends Node
class_name MapCameraController
## Gère la transition entre la pièce (RoomView : bouton carte + bureau +
## boutique) et l'écran de la carte de paris (Main / race_track). En 3D
## c'était un zoom de caméra ; en 2D c'est un fondu + scale, avec le pivot
## calé sur le bouton "Carte des paris" pour donner l'impression qu'on
## plonge vers lui (et qu'on en ressort au retour).
## NB : on cache toute la pièce (`RoomView`), pas juste le bureau, sinon le
## bouton "Carte des paris" reste visible par-dessus l'écran de course.
## Le fond (`Background`, qui porte la TileMapLayer) suit le même zoom que
## RoomView pour l'effet visuel, mais reste toujours visible/opaque : Main
## (l'écran de course) n'a pas de fond opaque à lui, donc s'il disparaissait
## aussi on verrait le gris par défaut du viewport derrière l'UI de la carte.

const ZOOM_SCALE := 2.2
# Position verticale du pivot de zoom du fond, en fraction de la hauteur
# de l'écran (0.0 = tout en haut, 0.5 = centre, 1.0 = tout en bas).
# Volontairement < 0.5 pour que le zoom garde le haut de la scène
# (READY, CAISSE/TRANCHE) bien en vue plutôt que de centrer pile au milieu.
const BACKGROUND_PIVOT_Y_FACTOR := 0.3

var zoomed_in_state: bool = false

var _room_view: Control
var _background: Control
var _main_ui: Control
var _btn_back: Button
var _btn_shop: Button
var _map_desk: Button

func setup(room_view: Control, main_ui: Control, btn_back: Button, btn_shop: Button, map_desk: Button, background: Control = null) -> void:
	_room_view = room_view
	_background = background
	_main_ui = main_ui
	_btn_back = btn_back
	_btn_shop = btn_shop
	_map_desk = map_desk
	_btn_back.pressed.connect(zoom_out)
	_btn_back.visible = false
	_main_ui.visible = false
	_set_ui_interactive(false)

func _pivot_for(node: Control) -> Vector2:
	# Centre du bouton "Carte des paris", ramené dans le repère local du
	# noeud donné (l'espace attendu par pivot_offset), pour que le scale
	# converge vers le bouton plutôt que vers le centre de l'écran.
	var btn_center_global = _map_desk.global_position + _map_desk.size / 2.0
	return node.get_global_transform().affine_inverse() * btn_center_global

func _center_pivot_for(node: Control) -> Vector2:
	# Le fond (décor du bureau réutilisé comme arrière-plan derrière la
	# carte) doit rester centré à l'écran pendant son zoom, pas converger
	# vers le bouton "Carte des paris" comme RoomView : sinon la zone verte
	# se retrouve décalée une fois sur la carte. Le pivot est remonté par
	# rapport au centre exact via BACKGROUND_PIVOT_Y_FACTOR.
	return Vector2(node.size.x / 2.0, node.size.y * BACKGROUND_PIVOT_Y_FACTOR)

func zoom_in() -> void:
	if zoomed_in_state:
		return
	zoomed_in_state = true
	_btn_shop.visible = false
	_set_ui_interactive(false)

	_room_view.pivot_offset = _pivot_for(_room_view)
	if _background:
		_background.pivot_offset = _center_pivot_for(_background)

	var tween_out = create_tween()
	tween_out.set_parallel(true)
	tween_out.tween_property(_room_view, "modulate:a", 0.0, 0.3)
	tween_out.tween_property(_room_view, "scale", Vector2(ZOOM_SCALE, ZOOM_SCALE), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if _background:
		# Le fond zoome avec la pièce, mais ne se fond pas en transparence :
		# il doit rester en place comme arrière-plan derrière Main.
		tween_out.tween_property(_background, "scale", Vector2(ZOOM_SCALE, ZOOM_SCALE), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween_out.finished
	_room_view.visible = false
	_room_view.scale = Vector2.ONE
	# _background reste volontairement à l'échelle ZOOM_SCALE ici : tant
	# qu'on est sur la carte, le décor doit rester zoomé (il ne redevient
	# normal qu'au zoom_out). Il reste visible en permanence (jamais caché),
	# Main n'ayant pas de fond opaque à lui, sans quoi le gris par défaut du
	# viewport apparaîtrait dans les zones non couvertes par son UI.

	_main_ui.modulate.a = 0.0
	_main_ui.scale = Vector2(0.9, 0.9)
	_main_ui.pivot_offset = _main_ui.size / 2.0
	_main_ui.visible = true
	var tween_in = create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(_main_ui, "modulate:a", 1.0, 0.3)
	tween_in.tween_property(_main_ui, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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

	_room_view.pivot_offset = _pivot_for(_room_view)
	_room_view.scale = Vector2(ZOOM_SCALE, ZOOM_SCALE)
	_room_view.modulate.a = 0.0
	_room_view.visible = true
	if _background:
		_background.pivot_offset = _center_pivot_for(_background)
		_background.scale = Vector2(ZOOM_SCALE, ZOOM_SCALE)
	var tween_in = create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(_room_view, "modulate:a", 1.0, 0.3)
	tween_in.tween_property(_room_view, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _background:
		tween_in.tween_property(_background, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween_in.finished
	_btn_shop.visible = true

func _set_ui_interactive(active: bool) -> void:
	_main_ui.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE

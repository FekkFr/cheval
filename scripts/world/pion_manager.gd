extends Node
class_name PionManager
## Gère le ciblage des pions (chevaux). Version 2D : les pions sont des
## Button, donc plus besoin d'Area3D/CollisionShape3D pour détecter le clic —
## on écoute juste le signal `pressed`. Le surlignage à la sélection se fait
## par teinte (modulate) au lieu d'un matériau émissif 3D.

signal selection_started(horse: Horse)
signal target_confirmed
signal selection_cancelled

const HIGHLIGHT_COLOR := Color("#e8d5b0")
const DEFAULT_COLOR := Color(1, 1, 1, 1)
const SELECTED_SCALE := Vector2(1.15, 1.15)

var _pion_bg: ColorRect
var _pions: Array
var _main_ui
var _btn_shop: Button
var _btn_back_shop: Button

var _pending_index: int = -1
var _pending_pion: Control = null

func setup(pion_bg: ColorRect, pions: Array, main_ui, btn_shop: Button, btn_back_shop: Button) -> void:
	_pion_bg = pion_bg
	_pions = pions
	_main_ui = main_ui
	_btn_shop = btn_shop
	_btn_back_shop = btn_back_shop

	for i in _pions.size():
		var pion: Control = _pions[i]
		pion.pivot_offset = pion.size / 2.0
		pion.pressed.connect(_on_clicked.bind(i))

	# Les boutons affichent le vrai nom du cheval au lieu de "Cheval N", et se
	# remettent à jour à chaque nouvelle course (nouveaux chevaux générés).
	GameState.race_finished.connect(refresh_names)
	refresh_names()

func refresh_names() -> void:
	for i in _pions.size():
		if i < GameState.current_horses.size():
			_pions[i].text = GameState.current_horses[i].horse_name

func has_pending() -> bool:
	return _pending_index != -1

func get_pending_index() -> int:
	return _pending_index

func _on_clicked(index: int) -> void:
	if has_pending():
		return

	var horse = GameState.current_horses[index]
	_pending_index = index
	_pending_pion = _pions[index]
	# On cache immédiatement les boutons de navigation (pas d'attente du tween)
	_btn_shop.visible = false
	_btn_back_shop.visible = false

	_set_highlight(_pending_pion, true)

	var tween = create_tween()
	tween.tween_property(_pending_pion, "scale", SELECTED_SCALE, 0.2).set_trans(Tween.TRANS_BACK)

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

	var tween = create_tween()
	tween.tween_property(pion_to_reset, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)
	_set_highlight(pion_to_reset, false)

	_pending_index = -1
	_pending_pion = null

func _set_highlight(pion_node: Control, enabled: bool) -> void:
	pion_node.modulate = HIGHLIGHT_COLOR if enabled else DEFAULT_COLOR

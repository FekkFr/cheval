extends Node
class_name ShopManager
## Gère la boutique. Version 2D : les emplacements sont des Button (plus
## besoin d'Area3D), et "zoomer vers la boutique" devient simplement un
## fondu entre DeskView (chevaux/bureau) et ShopView (les 3 emplacements),
## au lieu de faire tourner une caméra dans la pièce.

signal item_selection_started(mod: ModifierBase)
signal item_selection_cancelled
signal purchase_confirmed

const HIGHLIGHT_COLOR := Color("#e8d5b0")
const DEFAULT_COLOR := Color(1, 1, 1, 1)
const SELECTED_SCALE := Vector2(1.15, 1.15)

var in_shop: bool = false

var _desk_view: Control
var _shop_view: Control
var _btn_shop: Button
var _btn_back_shop: Button
var _pion_bg: ColorRect
var _emplacements: Array
var _boite_names: Dictionary
var _shop_modifiers: Array = []
var _map_desk: Control
var _pions_view: Control

var _pending_index: int = -1
var _pending_node: Control = null

func setup(desk_view: Control, shop_view: Control, btn_shop: Button, btn_back_shop: Button, pion_bg: ColorRect, emplacements: Array, boite_names: Dictionary, map_desk: Control = null, pions_view: Control = null) -> void:
	_desk_view = desk_view
	_shop_view = shop_view
	_btn_shop = btn_shop
	_btn_back_shop = btn_back_shop
	_pion_bg = pion_bg
	_emplacements = emplacements
	_boite_names = boite_names
	_map_desk = map_desk
	_pions_view = pions_view

	_shop_view.visible = false

	_btn_shop.pressed.connect(zoom_to_shop)
	_btn_back_shop.pressed.connect(zoom_back_from_shop)
	_btn_back_shop.visible = false

	for i in _emplacements.size():
		var emplacement: Control = _emplacements[i]
		emplacement.pivot_offset = emplacement.size / 2.0
		emplacement.pressed.connect(_on_clicked.bind(i))

	GameState.race_finished.connect(refresh_shop)
	refresh_shop()

func has_pending() -> bool:
	return _pending_index != -1

func zoom_to_shop() -> void:
	in_shop = true
	_btn_shop.visible = false
	_btn_back_shop.visible = true

	var tween_out = create_tween()
	tween_out.tween_property(_desk_view, "modulate:a", 0.0, 0.2)
	await tween_out.finished
	_desk_view.visible = false

	_shop_view.visible = true
	_shop_view.modulate.a = 0.0
	var tween_in = create_tween()
	tween_in.tween_property(_shop_view, "modulate:a", 1.0, 0.2)
	await tween_in.finished

func zoom_back_from_shop() -> void:
	in_shop = false
	_btn_back_shop.visible = false
	_btn_shop.visible = true

	var tween_out = create_tween()
	tween_out.tween_property(_shop_view, "modulate:a", 0.0, 0.2)
	await tween_out.finished
	_shop_view.visible = false

	_desk_view.visible = true
	_desk_view.modulate.a = 0.0
	# "Carte des paris" et les pions sont des enfants de DeskView, mais leur
	# propre visibilité (mise à false par _close_selection_popup après un
	# achat, tant qu'on est encore dans la boutique) ne suit pas celle du
	# parent : il faut les remontrer explicitement en quittant la boutique,
	# sinon ils restent cachés pour de bon même une fois DeskView revisible.
	if _map_desk:
		_map_desk.visible = true
	if _pions_view:
		_pions_view.visible = true
	var tween_in = create_tween()
	tween_in.tween_property(_desk_view, "modulate:a", 1.0, 0.2)
	await tween_in.finished

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

func _on_clicked(index: int) -> void:
	if not in_shop or has_pending():
		return
	if index >= _shop_modifiers.size():
		return

	var mod = _shop_modifiers[index]
	_pending_index = index
	_pending_node = _emplacements[index]
	_btn_back_shop.visible = false

	_set_highlight_boite(mod, true)

	var tween = create_tween()
	tween.tween_property(_pending_node, "scale", SELECTED_SCALE, 0.2).set_trans(Tween.TRANS_BACK)

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

	var tween = create_tween()
	tween.tween_property(_pending_node, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)

	_set_highlight_boite(mod, false)

	_pending_index = -1
	_pending_node = null
	purchase_confirmed.emit()

func cancel_selection() -> void:
	if _pending_node == null:
		return

	var mod = _shop_modifiers[_pending_index]
	var tween = create_tween()
	tween.tween_property(_pending_node, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)
	_set_highlight_boite(mod, false)
	await tween.finished

	_pending_index = -1
	_pending_node = null
	item_selection_cancelled.emit()

func _set_highlight_boite(mod: ModifierBase, enabled: bool) -> void:
	var boite_name = _boite_names.get(mod.mod_id, "")
	if boite_name == "" or _pending_node == null:
		return
	var boite = _pending_node.get_node_or_null(boite_name)
	if boite:
		boite.modulate = HIGHLIGHT_COLOR if enabled else DEFAULT_COLOR

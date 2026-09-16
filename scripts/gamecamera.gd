extends Control
## Contrôleur principal de l'écran de la pièce (world.tscn), version 2D.
## Relie les entrées du joueur aux sous-systèmes dédiés :
##   - HudDisplay          → badges CAISSE / TRANCHE
##   - MapCameraController → transition vers la carte de paris (ex-zoom caméra)
##   - ShopManager         → boutique (objets à acheter)
##   - PionManager         → ciblage des chevaux (pions)
## et gère la popup de sélection, partagée entre la boutique et le ciblage.

@onready var btn_shop = $BtnShop
@onready var btn_back_shop = $BtnBackShop
@onready var main_ui = $Main
@onready var btn_back = $BtnBack
@onready var map_desk = $RoomView/DeskView/MapDesk
@onready var label_cash_world = $PanelMoney/VBoxMoney/LabelCashWorld
@onready var label_tranche_world = $PanelMoney/VBoxMoney/LabelTrancheWorld
@onready var panel_money = $PanelMoney
@onready var pion_bg = $PionBg
@onready var pion_popup = $PionPopup
@onready var btn_cancel = $PionPopup/BtnCancel
@onready var pion_label = $PionPopup/LabelHorseName
@onready var btn_confirm = $PionPopup/BtnConfirm
@onready var mod_list = $PionPopup/ModifierList
@onready var room_view = $RoomView
@onready var desk_view = $RoomView/DeskView
@onready var shop_view = $RoomView/ShopView
@onready var pions_view = $RoomView/DeskView/Pions
@onready var pions = [
	$RoomView/DeskView/Pions/Pion1,
	$RoomView/DeskView/Pions/Pion2,
	$RoomView/DeskView/Pions/Pion3,
	$RoomView/DeskView/Pions/Pion4
]
@onready var emplacements = [
	$RoomView/ShopView/Emplacement1,
	$RoomView/ShopView/Emplacement2,
	$RoomView/ShopView/Emplacement3
]
@onready var desk_slots = [
	$RoomView/DeskView/Bureau/Slot1,
	$RoomView/DeskView/Bureau/Slot2,
	$RoomView/DeskView/Bureau/Slot3,
	$RoomView/DeskView/Bureau/Slot4
]
@onready var extra_desk = $RoomView/DeskView/Bureau/BureauSupplementaire

var _boite_names = {
	"mod_sabotage": "sabotage",
	"mod_stimulant": "stimulant",
	"mod_rumeur": "rumeur",
	"mod_pari_perso": "paris",
	"mod_sabotage_discret": "sabodiscret",
	"mod_deskupgrade" : "deskupgrade"
}

var _selected_mod: ModifierBase = null

var hud: HudDisplay
var map_nav: MapCameraController
var shop: ShopManager
var desk: DeskManager
var pion_manager: PionManager

# ── Ready ─────────────────────────────────────────
func _ready():
	hud = HudDisplay.new()
	add_child(hud)
	hud.setup(panel_money, label_cash_world, label_tranche_world)

	map_nav = MapCameraController.new()
	add_child(map_nav)
	map_nav.setup(room_view, main_ui, btn_back, btn_shop)
	map_desk.pressed.connect(map_nav.zoom_in)

	shop = ShopManager.new()
	add_child(shop)
	shop.setup(desk_view, shop_view, btn_shop, btn_back_shop, pion_bg, emplacements, _boite_names, map_desk, pions_view)
	shop.item_selection_started.connect(_on_shop_item_selected)
	shop.item_selection_cancelled.connect(_close_selection_popup)
	shop.purchase_confirmed.connect(_close_selection_popup)

	desk = DeskManager.new()
	add_child(desk)
	desk.setup(desk_slots, _boite_names, extra_desk)

	pion_manager = PionManager.new()
	add_child(pion_manager)
	pion_manager.setup(pion_bg, pions, main_ui, btn_shop, btn_back_shop)
	pion_manager.selection_started.connect(_on_pion_selected)
	pion_manager.selection_cancelled.connect(_close_selection_popup)
	pion_manager.target_confirmed.connect(_close_selection_popup)

	_style_popup()

	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)

func _process(_delta):
	hud.refresh_tranche()

# ── Popup de sélection (partagée boutique / ciblage) ──
func _style_popup():
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

func _on_shop_item_selected(mod: ModifierBase) -> void:
	var pas_assez_tickets = ModifierManager.tickets < mod.cost
	var slots_pleins = ModifierManager.active_modifiers.size() >= ModifierManager.max_slots
	var deja_actif = false
	for active in ModifierManager.active_modifiers:
		if active.mod_id == mod.mod_id:
			deja_actif = true
			break

	btn_confirm.disabled = pas_assez_tickets or slots_pleins or deja_actif
	pion_label.text = mod.mod_name
	btn_confirm.visible = true
	pion_popup.visible = true

func _on_pion_selected(horse: Horse) -> void:
	# Le bureau reste visible (dimmé) derrière la popup, mais "Carte des
	# paris" et les autres pions gêneraient visuellement par-dessus : on les
	# cache le temps du choix (le nom du cheval choisi est déjà affiché en
	# grand dans la popup, pas besoin de garder les boutons visibles).
	map_desk.visible = false
	pions_view.visible = false
	pion_label.text = horse.horse_name

	for child in mod_list.get_children():
		child.queue_free()
	_selected_mod = null

	var mods_waiting = []
	for mod in ModifierManager.active_modifiers:
		if mod.needs_target and mod.target_index == -1:
			mods_waiting.append(mod)

	if mods_waiting.size() == 0:
		btn_confirm.visible = false
	else:
		for mod in mods_waiting:
			var btn = Button.new()
			btn.text = mod.mod_name + " - " + mod.description
			btn.pressed.connect(_on_mod_selected.bind(mod, btn))
			mod_list.add_child(btn)
	btn_confirm.visible = true
	pion_popup.visible = true
	btn_confirm.disabled = main_ui.waiting_for_target == null

func _on_mod_selected(mod: ModifierBase, btn: Button) -> void:
	_selected_mod = mod
	btn_confirm.disabled = false

	for child in mod_list.get_children():
		child.add_theme_color_override("font_color", Color("#736546ff"))
	btn.add_theme_color_override("font_color", Color("#c8860a"))

func _on_confirm_pressed() -> void:
	if shop.has_pending():
		shop.confirm_purchase()
	elif pion_manager.has_pending() and _selected_mod != null:
		# Appliquer le mod sélectionné au cheval ciblé
		_selected_mod.target_index = pion_manager.get_pending_index()
		ModifierManager.mark_modifier_used(_selected_mod)
		_selected_mod = null

		# Vérifier s'il reste des mods en attente pour ce même cheval
		var mods_restants = []
		for mod in ModifierManager.active_modifiers:
			if mod.needs_target and mod.target_index == -1:
				mods_restants.append(mod)

		if mods_restants.size() > 0:
			# Rafraîchir la liste sans fermer le popup
			for child in mod_list.get_children():
				child.queue_free()
			for mod in mods_restants:
				var btn = Button.new()
				btn.text = mod.mod_name
				btn.pressed.connect(_on_mod_selected.bind(mod, btn))
				mod_list.add_child(btn)
			btn_confirm.disabled = true  # reset jusqu'à nouvelle sélection
		else:
			# Plus rien en attente — prévenir l'ancien système (main.gd) que le
			# ciblage est terminé, sinon btn_launch reste désactivé (bug du double confirm)
			if main_ui.waiting_for_target != null:
				main_ui.waiting_for_target = null
				main_ui._enable_horse_targeting(false)
			pion_manager.cancel_selection()
	elif pion_manager.has_pending():
		pion_manager.confirm_target()

func _on_cancel_pressed() -> void:
	# Annule soit un pion soit une boite boutique
	if pion_manager.has_pending():
		pion_manager.cancel_selection()
	elif shop.has_pending():
		shop.cancel_selection()

func _close_selection_popup() -> void:
	var tween_bg = create_tween()
	tween_bg.tween_property(pion_bg, "color:a", 0.0, 0.3)
	await tween_bg.finished
	pion_bg.visible = false
	pion_popup.visible = false
	btn_back_shop.visible = shop.in_shop
	btn_shop.visible = not shop.in_shop
	map_desk.visible = not shop.in_shop
	pions_view.visible = not shop.in_shop

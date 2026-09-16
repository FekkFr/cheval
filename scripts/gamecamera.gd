extends Node3D
## Contrôleur principal de la pièce 3D (world.tscn).
## Relie les entrées du joueur aux sous-systèmes dédiés :
##   - HudDisplay          → badges CAISSE / TRANCHE
##   - MapCameraController → zoom sur la carte de paris
##   - ShopManager         → boutique (objets à acheter)
##   - PionManager         → ciblage des chevaux (pions)
## et gère la popup de sélection, partagée entre la boutique et le ciblage.

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
@onready var mod_list = $CanvasLayer/PionPopup/ModifierList
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
@onready var desk_slots = [
	$Room/Bureau/Slot1,
	$Room/Bureau/Slot2,
	$Room/Bureau/Slot3,
	$Room/Bureau/Slot4
]
@onready var extra_desk = $Room/Furnitures/BureauSupplementaire

var _boite_names = {
	"mod_sabotage": "sabotage",
	"mod_stimulant": "stimulant",
	"mod_rumeur": "rumeur",
	"mod_pari_perso": "paris",
	"mod_sabotage_discret": "sabodiscret",
	"mod_deskupgrade" : "deskupgrade"
}

var default_cam_pos: Vector3
var default_cam_rot: Vector3

var _selected_mod: ModifierBase = null

var hud: HudDisplay
var map_camera: MapCameraController
var shop: ShopManager
var desk: DeskManager
var pion_manager: PionManager

# ── Ready ─────────────────────────────────────────
func _ready():
	default_cam_pos = camera.position
	default_cam_rot = camera.rotation

	hud = HudDisplay.new()
	add_child(hud)
	hud.setup(panel_money, label_cash_world, label_tranche_world)

	map_camera = MapCameraController.new()
	add_child(map_camera)
	map_camera.setup(camera, main_ui, btn_back, btn_shop, default_cam_pos, default_cam_rot)
	click_area.input_event.connect(map_camera.on_carte_clicked)

	shop = ShopManager.new()
	add_child(shop)
	shop.setup(camera, btn_shop, btn_back_shop, pion_bg, emplacements, _boite_names, default_cam_pos, default_cam_rot)
	shop.item_selection_started.connect(_on_shop_item_selected)
	shop.item_selection_cancelled.connect(_close_selection_popup)
	shop.purchase_confirmed.connect(_close_selection_popup)

	desk = DeskManager.new()
	add_child(desk)
	desk.setup(desk_slots, _boite_names, extra_desk)

	pion_manager = PionManager.new()
	add_child(pion_manager)
	pion_manager.setup(camera, pion_bg, pions, main_ui, btn_shop, btn_back_shop)
	pion_manager.selection_started.connect(_on_pion_selected)
	pion_manager.selection_cancelled.connect(_close_selection_popup)
	pion_manager.target_confirmed.connect(_close_selection_popup)

	_style_popup()

	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)

func _process(delta):
	hud.refresh_tranche()
	pion_manager.process_rotation(delta)

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

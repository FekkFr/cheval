extends Node3D

@onready var camera = $Camera3D
@onready var main_ui = $CanvasLayer/Main
@onready var btn_back = $CanvasLayer/BtnBack
@onready var click_area = $Carte/Cube/ClickArea
@onready var label_cash_world = $CanvasLayer/PanelMoney/VBoxMoney/LabelCashWorld
@onready var label_tranche_world = $CanvasLayer/PanelMoney/VBoxMoney/LabelTrancheWorld
@onready var panel_money = $CanvasLayer/PanelMoney

var zoomed_in = false
var default_cam_pos: Vector3
var default_cam_rot: Vector3
var zoom_cam_pos = Vector3(0.226, 3.848, 0.0)
var zoom_cam_rot = Vector3(deg_to_rad(-1.7), deg_to_rad(-90.0), deg_to_rad(0.0)) 

func _refresh_hud_world():
	label_cash_world.text = "CAISSE : $" + str(int(GameState.cash))
	label_tranche_world.text = "TRANCHE : $" + str(int(GameState.get_weekly_payment()))
func _on_cash_changed_world(amount):
	label_cash_world.text = "CAISSE : $" + str(int(amount))
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

func _ready():
	default_cam_pos = camera.position
	default_cam_rot = camera.rotation
	click_area.input_event.connect(_on_carte_clicked)
	btn_back.pressed.connect(_on_back_pressed)
	btn_back.visible = false
	main_ui.visible = false  # ← caché au départ
	_set_ui_interactive(false)
	GameState.cash_changed.connect(_on_cash_changed_world)
	_refresh_hud_world()
	_style_money_badges()

func _on_carte_clicked(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and not zoomed_in:
		_zoom_to_carte()

func _process(_delta):
	label_tranche_world.text = "TRANCHE : $" + str(int(GameState.get_weekly_payment()))

func _zoom_to_carte():
	zoomed_in = true
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
	btn_back.visible = false
	_set_ui_interactive(false)
	main_ui.visible = false  # ← caché en sortant

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "position", default_cam_pos, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "rotation", default_cam_rot, 1.0).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	main_ui.scale = Vector2(0.3, 0.3)
	main_ui.position = Vector2(412.74, 100.0)

func _set_ui_interactive(active: bool):
	main_ui.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE

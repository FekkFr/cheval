extends Node
class_name HudDisplay

var label_cash: Label
var label_tranche: Label

func setup(panel_money: PanelContainer, cash_label: Label, tranche_label: Label) -> void:
	label_cash = cash_label
	label_tranche = tranche_label
	_style_money_badges(panel_money)
	GameState.cash_changed.connect(_on_cash_changed)
	refresh()

func refresh() -> void:
	label_cash.text = "CAISSE : $" + str(int(GameState.cash))
	refresh_tranche()

func refresh_tranche() -> void:
	label_tranche.text = "TRANCHE : $" + str(int(GameState.get_weekly_payment()))

func _on_cash_changed(amount) -> void:
	label_cash.text = "CAISSE : $" + str(int(amount))

func _style_money_badges(panel_money: PanelContainer) -> void:
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
	for label in [label_cash, label_tranche]:
		if font:
			label.add_theme_font_override("font", font)
			label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color("#e8d5b0"))

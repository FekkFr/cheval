extends Node
class_name DeskManager
## Affiche sur le bureau les objets actuellement possédés (achetés à la
## boutique). Logique inchangée par rapport à la version 3D — seul le type
## des nœuds change (Node3D → Control), le reste ne dépendait pas de la 3D.
## (et tentative de supprimer du bureau (code a refaire))

const EXTRA_DESK_MOD_ID := "mod_deskupgrade"  # ce mod n'affiche pas de boîte dans un Slot,
											   # il fait apparaître _extra_desk à la place

var _slots: Array = []             # Array[Control] – emplacements du bureau
var _boite_names: Dictionary = {}  # mod_id -> nom du noeud placeholder
var _extra_desk: Control = null    # bureau supplémentaire (effet visuel de mod_deskupgrade)

func setup(slots: Array, boite_names: Dictionary, extra_desk: Control = null) -> void:
	_slots = slots
	_boite_names = boite_names
	_extra_desk = extra_desk

	ModifierManager.modifier_activated.connect(_on_modifiers_changed)
	ModifierManager.modifier_expired.connect(_on_modifiers_changed)
	ModifierManager.modifier_used.connect(_on_modifiers_changed)

	refresh_desk()

func _on_modifiers_changed(_mod: ModifierBase) -> void:
	refresh_desk()

func refresh_desk() -> void:
	var active = ModifierManager.active_modifiers

	if _extra_desk:
		var has_desk_upgrade = false
		for mod in active:
			if mod.mod_id == EXTRA_DESK_MOD_ID:
				has_desk_upgrade = true
				break
		_extra_desk.visible = has_desk_upgrade

	for i in _slots.size():
		var slot = _slots[i]
		for model_name in _boite_names.values():
			var model = slot.get_node_or_null(model_name)
			if model:
				model.visible = false

		if i < active.size():
			var mod = active[i]
			if mod.used or mod.mod_id == EXTRA_DESK_MOD_ID:
				continue
			var model_name = _boite_names.get(mod.mod_id, "")
			if model_name != "":
				var model = slot.get_node_or_null(model_name)
				if model:
					model.visible = true

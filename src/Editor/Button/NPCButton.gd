extends MarginContainer

signal npc_changed(npc_path)

var npc_path: String
var npc_name: String
var npc_sprite: Texture2D
var active = false

func _ready():
	%Label.text = npc_name
	%TextureRect.texture = npc_sprite
	%PanelActive.visible = active

func activate():
	for e in get_tree().get_nodes_in_group("NPCButtons"):
		e.deactivate()
	%PanelActive.visible = true
	active = true

func deactivate():
	%PanelActive.visible = false
	active = false


func _on_button_pressed():
	activate()
	emit_signal("npc_changed", npc_path)

extends MarginContainer

signal npc_changed(npc_path)

var npc_path: String
var npc_name: String
var active = false

func _ready():
	add_to_group("NPCButtons")
	$HBox/Button.text = npc_name
	$PanelActive.visible = active


func on_pressed():
	activate()
	emit_signal("npc_changed", npc_path)


func activate():
	for e in get_tree().get_nodes_in_group("NPCButtons"):
		e.deactivate()
	$PanelActive.visible = true
	active = true

func deactivate():
	$PanelActive.visible = false
	active = false

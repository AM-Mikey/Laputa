extends MarginContainer

signal tab_selected(tab_index)

var icon
var tab_index: int
var enabled = true

@onready var w = get_tree().get_root().get_node("World")
@onready var cl = w.current_level

func _ready():
	$VBox/TextureRect.texture = icon
	$VBox/TextureRect/Shadow.texture = icon
	$VBox/TextureRect/Highlight.texture = icon


func on_pressed():
	emit_signal("tab_selected", tab_index)

func _on_gui_input(event: InputEvent):
	if event.is_action_pressed("editor_rmb"):
		if enabled:
			$TabButton.disabled = true
			$VBox/TextureRect.self_modulate = Color.TRANSPARENT
			enabled = false
			set_collection_visibility(false)
		else:
			$TabButton.disabled = false
			$VBox/TextureRect.self_modulate = Color.WHITE
			enabled = true
			set_collection_visibility(true)


func set_collection_visibility(visible):
	match tab_index:
		0: cl.get_node("TileMap").visible = visible
		1: pass
		2: pass
		3: for a in cl.get_node("Spawns").get_children():
			if a.is_in_group("EnemySpawns"):
				a.visible = visible
		4: for a in cl.get_node("Spawns").get_children():
			if a.is_in_group("NPCSpawns"):
				a.visible = visible
		5: cl.get_node("Props").visible = visible
		6: cl.get_node("Triggers").visible = visible
	

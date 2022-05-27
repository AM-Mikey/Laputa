extends MarginContainer

const PROPERTY_BUTTON = preload("res://src/editor/PropertyButton.tscn")

onready var editor = get_parent().get_parent()

var active
var active_type: String


func on_background_selected(background):
	clear_data()
	active = background
	active_type = "background"
	display_background_data(active)
	$Margin/VBox/Label.text = active.name

func display_background_data(background):
	var level_rect = background.get_node("Margin/LevelRect")
	var limiter = background.level_limiter
	
#	create_button("margin_left", level_rect.margin_left)
#	create_button("margin_top", level_rect.margin_top)
#	create_button("margin_right", level_rect.margin_right)
#	create_button("margin_bottom", level_rect.margin_bottom)

	create_button("texture", limiter.texture.resource_path)
	create_button("layers", limiter.layers)
	create_button("parallax_near", limiter.parallax_near)
	create_button("parallax_far", limiter.parallax_far)
	create_button("focus", limiter.focus)
	create_button("tile_mode", limiter.tile_mode)


func on_enemy_selected(enemy):
	clear_data()
	if active: #previous selection
		if active_type == "enemy":
			active.modulate = Color(1,1,1)
	if enemy:
		active = enemy
		active_type = "enemy"
		active.modulate = Color(2,2,2)
		display_enemy_data(active)
		$Margin/VBox/Label.text = active.name
	else: #null selection
		active = null

func display_enemy_data(enemy):
	#print(enemy.get_property_list())
	for p in enemy.get_property_list():
		if p["usage"] == 8199: #exported properties
			create_button(p["name"], enemy.get(p["name"]), p["type"])





func on_property_changed(property_name, property_value):
	match active_type:
		"enemy":
			active.set(property_name, property_value)
		"background":
			match property_name:
				"margin_left", "margin_top", "margin_right", "margin_bottom":
					pass
				"texture", "layers", "parallax_near", "parallax_far", "focus", "tile_mode":
					active.level_limiter.set(property_name, property_value)
					active.level_limiter.setup_layers()
					active.level_limiter.set_focus()
					
	print("Changed " + active_type + " " + active.name + "'s " + property_name + " to " + String(property_value))







### HELPERS

func clear_data():
	$Margin/VBox/Label.text = ""
	for c in $Margin/VBox/Scroll/VBox.get_children():
		c.queue_free()

func create_button(property, value, type = TYPE_NIL):
	var button = PROPERTY_BUTTON.instance()
	button.property_name = property
	button.property_value = value
	button.property_type = type
	$Margin/VBox/Scroll/VBox.add_child(button)
	button.connect("property_changed", self, "on_property_changed")

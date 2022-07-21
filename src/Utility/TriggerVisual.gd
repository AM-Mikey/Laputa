extends ColorRect

onready var world = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("TriggerVisuals")
	
	color = get_parent().color
	
	get_parent().z_index = 100
	var col
	if get_parent().has_node("CollisionShape2D"):
		col = get_parent().get_node("CollisionShape2D")
		rect_position = col.position - col.shape.extents
		rect_size = col.shape.extents * 2
	
	visible = world.debug_visible

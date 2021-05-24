extends CanvasLayer

onready var world = get_tree().get_root().get_node("World")
onready var bk = $Background

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	bk.rect_size = get_tree().get_root().size
	bk.rect_scale = Vector2(world.resolution_scale, world.resolution_scale)
	bk.visible = true
	
func _on_viewport_size_changed():
	bk.rect_size = get_tree().get_root().size
	bk.rect_scale = Vector2(world.resolution_scale, world.resolution_scale)

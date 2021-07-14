extends Control

onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()

func display_text(level_name):
	$AnimationPlayer.stop()
	$MarginContainer/Label.text = level_name
	visible = true
	$AnimationPlayer.play("Fade")
	yield($AnimationPlayer, "animation_finished")
	visible = false


func _on_viewport_size_changed():
	$MarginContainer.rect_size = get_tree().get_root().size / world.resolution_scale

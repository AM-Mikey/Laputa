extends Control

var text
var wait_time = 0.2

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "_on_viewport_size_changed"))
	_on_viewport_size_changed()
	$Label.text = text
	$Timer.start(wait_time)
	
	
func _on_Timer_timeout():
	display_text()

func display_text():
	$AnimationPlayer.play("Fade")
	await $AnimationPlayer.animation_finished
	queue_free()


func _on_viewport_size_changed():
	size = get_tree().get_root().size / world.resolution_scale



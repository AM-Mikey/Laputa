extends Control

var text
var wait_time = 0.2

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	$Label.text = text
	$Timer.start(wait_time)
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)



### SIGNALS ###

func _on_Timer_timeout():
	display_text()

func display_text():
	$AnimationPlayer.play("Fade")
	await $AnimationPlayer.animation_finished
	queue_free()

func _resolution_scale_changed(resolution_scale):
	set_deferred("size", get_tree().get_root().size / resolution_scale)

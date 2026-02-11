extends Control

var item_name: String
var wait_time = 2.4
@onready var world = get_tree().get_root().get_node("World")

func _ready():
	%Label.text = "Got the [color=f3b131]%s[/color]!" %item_name
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


### SIGNALS ###

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FloatIn":
		await get_tree().create_timer(wait_time).timeout
		$AnimationPlayer.play("FloatOut")
	else:
		queue_free()

func _resolution_scale_changed(resolution_scale):
	set_deferred("size", get_tree().get_root().size / resolution_scale)

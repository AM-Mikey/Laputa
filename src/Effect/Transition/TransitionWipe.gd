extends Control

var animation: String

@onready var world = get_tree().get_root().get_node("World")

func _ready():
		print("playing in animation")
		var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
		on_viewport_size_changed()
		$AnimationPlayer.play(animation)
	
	
func play_out_animation():
	print("playing out animation")
	$AnimationPlayer.play(animation)
	


func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"WipeInLeft": animation = "WipeOutLeft" #$AnimationPlayer.play("WipeOutLeft")
		"WipeInRight": animation = "WipeOutRight" #$AnimationPlayer.play("WipeOutRight")
		"WipeInUp": animation = "WipeOutUp" #$AnimationPlayer.play("WipeOutUp")
		"WipeInDown": animation = "WipeOutDown" #$AnimationPlayer.play("WipeOutDown")
		
		"WipeOutLeft": queue_free()
		"WipeOutRight": queue_free()
		"WipeOutUp": queue_free()
		"WipeOutDown": queue_free()


func on_viewport_size_changed():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	$MarginContainer.size = viewport_size

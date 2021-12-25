extends Prop

onready var world = get_tree().get_root().get_node("World")

func _ready():
	$AnimationPlayer.play("Spin")

func _on_body_entered(body):
	active_pc = body

func _on_body_exited(_body):
	active_pc = null

func _input(event):
	if event.is_action_pressed("inspect") and active_pc != null:
		if not active_pc.disabled:
			$SFX.play()
			$AnimationPlayer.playback_speed = 0.5
			world.write_level_data_to_temp()
			world.write_player_data_to_save()
			world.copy_level_data_from_temp_to_save()

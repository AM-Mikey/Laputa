extends Prop

const ICON = preload("res://assets/Prop/LanternIcon.png")
var toggled = true

@export var style: int = 0

func setup(): #Reminder: no function called can use await
	$Sprite2D.frame_coords.y = style
	if toggled:
		$AnimationPlayer.play("On")
	else:
		$AnimationPlayer.play("Off")
	w.emit_signal("finished_spawn_entities_step")

func activate():
	am.play("prop_click")
	toggled = !toggled
	if toggled:
		$AnimationPlayer.play("On")
	else:
		$AnimationPlayer.play("Off")
	ms.mission_progress_check(id)


### SIGNALS ###

func _on_PlayerDetector_body_entered(body: Node2D):
	active_players.append(body.get_parent())


func _on_PlayerDetector_body_exited(body: Node2D):
	active_players.erase(body.get_parent())

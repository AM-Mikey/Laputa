extends Prop

var toggled = true

@export var style: int = 0

func setup():
	$Sprite2D.frame_coords.y = style
	if toggled:
		$AnimationPlayer.play("On")
	else:
		$AnimationPlayer.play("Off")

func activate():
	am.play("prop_click")
	toggled = !toggled
	if toggled:
		$AnimationPlayer.play("On")
	else:
		$AnimationPlayer.play("Off")


### SIGNALS ###

func _on_PlayerDetector_body_entered(body: Node2D):
	active_players.append(body.get_parent())


func _on_PlayerDetector_body_exited(body: Node2D):
	active_players.erase(body.get_parent())

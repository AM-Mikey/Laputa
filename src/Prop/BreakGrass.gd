extends StaticBody2D

func _ready():
	$AnimationPlayer.play("Tall")

func on_break(method):
	if method == "fire":
		$AnimationPlayer.play("Burn")
	else:
		$AnimationPlayer.play("Cut")
	

extends NPC


func _ready():
	id = "mechanic"
	conversation = "Cutscene1"
	$AnimationPlayer.play("StandLeft")

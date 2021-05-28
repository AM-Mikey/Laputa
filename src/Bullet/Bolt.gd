extends Bullet

var starting_time

func _ready():
	
	$AnimationPlayer.play("Section")
	$AnimationPlayer.seek(starting_time)

func _on_CollisionDetector_body_entered(body):
	if disabled == false:
		if body.get_collision_layer_bit(8): #breakable
					body.on_break("cut")
					if body.get_collision_layer_bit(3): #world
						visible = false
						disabled = true
						_fizzle_from_world()

		elif body.get_collision_layer_bit(0): #player
			var kb_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, kb_direction)
			queue_free()

func _on_Timer_timeout():
	pass
	#queue_free()

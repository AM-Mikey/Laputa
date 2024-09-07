extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var duration = 0.1

func _ready(): #TODO think about a particle based buckshot system? then you can stop on world
	$Timer.start(duration)
	rotation_degrees = get_rot(direction)

func _on_CollisionDetector_body_entered(body): #shadows parent
	#do not stop on world
	#do not stop on enemy
	if disabled:
		return
	if body is TileMap:
		pass
		#if body.tile_set.get_physics_layer_collision_layer(0) == 8: #world (layer value)
			#do_fizzle("world")
	else:
		#breakable
		if body.get_collision_layer_value(9): 
			on_break(break_method)
		#enemy
		elif body.get_collision_layer_value(2) and not is_enemy_bullet: 
			#await get_tree().process_frame
			body.hit(damage, get_blood_dir(body))
			queue_free()
		#player
		elif body.get_collision_layer_value(1) and is_enemy_bullet: 
			body.hit(damage, get_blood_dir(body))
		#armor #TODO:fix this interaction
		elif body.get_collision_layer_value(6):
			do_fizzle("armor")


func _on_Timer_timeout():
	queue_free()

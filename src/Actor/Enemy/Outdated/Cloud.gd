extends Enemy
const BOLT = preload("res://src/Bullet/Bolt.tscn")


var direction = Vector2.LEFT


func _ready():
	hp = 4
	damage_on_contact = 1
	$AnimationPlayer.play("Idle")
	
	reward = 4
	
	print($RayCast2D.get_collider())





func _on_FireCooldown_timeout():
	direction = Vector2.ZERO
	print("ok")
	var tilemap = $RayCast2D.get_collider()
	print(tilemap)

	if tilemap != null:
		var target_pos = global_position
		var local_pos = tilemap.to_local(target_pos)
		var map_pos = tilemap.world_to_map(local_pos)
		var target_cell = tilemap.get_cellv(map_pos)
		
		var starting_time = 0
		var ending_time = .4
		
		while target_cell == -1:
			map_pos.y += 1
			print(map_pos)
			target_cell = tilemap.get_cellv(map_pos)
			if target_cell == -1:
				var bolt = BOLT.instance()
				local_pos = tilemap.map_to_world(map_pos)
				bolt.global_position = tilemap.to_global(local_pos)
				bolt.global_position.x += 8
				bolt.global_position.y += 8
				bolt.starting_time = starting_time
			
				get_tree().get_current_scene().add_child(bolt)
				
				if starting_time < ending_time:
					starting_time += .1
				else:
					starting_time = 0
		

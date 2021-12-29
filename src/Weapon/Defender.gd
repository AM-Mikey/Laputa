extends Gun


func activate():
	var origin = pc.get_node("BulletOrigin").global_position
	spawn_bullet(origin, Vector2.LEFT)
	spawn_bullet(origin, Vector2.RIGHT)

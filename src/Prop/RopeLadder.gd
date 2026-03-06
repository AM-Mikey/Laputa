extends Prop

#TODO: this code should create multiple sprites for the ladder and repeat them with their animations offset to complete the effect.
#for maximum compatibility have the ladder unfurl until it hits the ground, using raycast this is possible
#add top of rope ladder, trigger area to interact and drop it.

var length: int
var sprites := []

func setup():
	await get_tree().process_frame #needs for some reason
	setup_length()

func setup_length():
	if $Ground.is_colliding():
		length = $Ground.get_collision_point().y - $Ground.global_position.y
		sprites.append($Sprite2D)
		var sprite_count = int(floor(length / 16.0))
		for i in sprite_count:
			var duplicated_sprite = $Sprite2D.duplicate(0)
			duplicated_sprite.global_position += Vector2(0, i * 16.0)
			add_child(duplicated_sprite)
			sprites.append(duplicated_sprite)

#func activate():
	#

extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D

var duration = 0.1



func _ready():
	default_body_collision = false
	$Timer.start(duration)
	rotation_degrees = get_rot(direction)

#shotgun bullets do not stop on world so it doesn't delete the bullet if it clipped world
#shotgun bullets can also go through multiple creatures, they only dissapear after their timer ends
func _on_Timer_timeout():
	queue_free()

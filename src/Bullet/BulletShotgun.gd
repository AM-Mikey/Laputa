extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var duration = 0.1



func _ready():
	$Timer.start(duration)
	rotation_degrees = get_rot(direction)

func _on_CollisionDetector_body_entered(_body): #shadows
	#shotgun bullets do not stop on world so it doesn't delete the bullet if it clipped world
	#shotgun bullets can also go through multiple creatures, they only dissapear after their timer ends	
	pass


func _on_Timer_timeout():
	queue_free()

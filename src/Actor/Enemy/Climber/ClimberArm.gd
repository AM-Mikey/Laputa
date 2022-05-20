extends Enemy

var part_type = "arm"
var index

func _ready():
	hp = 2
	damage_on_contact = 1
	reward = 1

func _process(_delta):
	if get_parent() != null:
		$Sprite.rotation = 2 * PI - get_parent().rotation


func die():
	if not dead:
		dead = true
		
		get_parent().arm_count -= 1
		get_parent().replace_arms(index)
		
		do_death_drop()
		$DamagenumTimer.stop()
		_on_DamagenumTimer_timeout()
		
		var explosion = EXPLOSION.instance()
		get_tree().get_root().get_node("World/Front").add_child(explosion)
		explosion.position = global_position
		
		if get_parent().get_parent() is Path2D:
			get_parent().get_parent().queue_free()
		else:
			queue_free()

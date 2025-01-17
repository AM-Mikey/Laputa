extends Enemy

var part_type = "body"

func _ready():
	hp = 4
	damage_on_contact = 2
	reward = 3

func _process(_delta):
	if get_parent() != null:
		$Sprite2D.rotation = 2 * PI - get_parent().rotation

func die():
	if not dead:
		dead = true
		

		
		do_death_drop()
		$DamagenumTimer.stop()
		_on_DamagenumTimer_timeout()
		
		pc.is_in_enemy = false #THIS IS A BAD WAY TO DO THIS if a player is in a different enemy when this one dies, they will be immune to that enemy
		
		var explosion = EXPLOSION.instantiate()
		get_tree().get_root().get_node("World/Front").add_child(explosion)
		explosion.position = global_position
		

		get_parent().queue_free()

extends Enemy

var part_type = "arm"
var index

func _ready():
	hp = 2
	damage_on_contact = 1
	level = 1

func _process(delta):
	if get_parent() != null:
		$Sprite.rotation = 2 * PI - get_parent().rotation


func die():
	if not dead:
		dead = true
		
#		get_parent().arm_count -= 1
#		get_parent().replace_arms()
		
		do_death_drop()
		timer.stop()
		_on_DamagenumTimer_timeout()
		
		player_actor.is_in_enemy = false #THIS IS A BAD WAY TO DO THIS if a player is in a different enemy when this one dies, they will be immune to that enemy
		
		var explosion = EXPLOSION.instance()
		get_tree().get_root().get_node("World/Front").add_child(explosion)
		explosion.position = global_position
		
		if get_parent().get_parent() is Path2D:
			get_parent().get_parent().queue_free()
		else:
			queue_free()

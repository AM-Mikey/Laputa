extends Enemy

var index: int

signal arm_die(arm)

func setup():
	hp = 2
	reward = 1
	damage_on_contact = 1
	$Label.visible = get_parent().get_parent().debug

func _on_physics_process(_delta):
	var parent_direction = global_position - get_parent().global_position
	var angle_to_parent = parent_direction.angle()
	var frame_index = posmod(round(angle_to_parent / (TAU / 8)), 8)
	$Sprite2D.frame_coords.x = frame_index

func do_death_routine():
	arm_die.emit(self)

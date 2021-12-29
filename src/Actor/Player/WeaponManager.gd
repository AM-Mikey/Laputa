extends Node

const LEVELUP = preload("res://src/Effect/LevelUp.tscn")
const LEVELDOWN = preload("res://src/Effect/LevelDown.tscn")

var disabled = false

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")


func _input(event):
	if not pc.disabled and not disabled and $Guns.get_child_count() > 0:
		var active_gun = $Guns.get_child(0)
		
		if event.is_action_pressed("fire_manual"):
			active_gun.fire("manual")
		if event.is_action_pressed("fire_automatic") and active_gun.automatic:
			active_gun.fire("automatic")
		if event.is_action_released("fire_manual") or event.is_action_released("fire_automatic"):
			active_gun.release_fire()

		if $Guns.get_child_count() > 1: #only swap if more than one gun
			if event.is_action_pressed("gun_left"):
				shift_gun("left")
			if event.is_action_pressed("gun_right"):
				shift_gun("right")

		if event.is_action_pressed("debug_level_up") and active_gun.level < active_gun.max_level:
				level_up(true)
		if event.is_action_pressed("debug_level_down") and active_gun.level != 1:
				level_down(true)


func shift_gun(direction):
	match direction:
		"left":
			var child_to_move = $Guns.get_child($Guns.get_child_count() - 1)
			$Guns.move_child(child_to_move, 0)
		"right":
			var child_to_move = $Guns.get_child(0)
			$Guns.move_child(child_to_move, $Guns.get_child_count() - 1)
			
	pc.emit_signal("guns_updated", $Guns.get_children())
	am.play("gun_shift")
	


func level_up(debug):
	var last_gun = $Guns.get_child(0)
	var next_gun = load(last_gun.resource_path.replace(last_gun.level, last_gun.level + 1))
	
	$Guns.add_child(next_gun)
	move_child(next_gun, 0)
	next_gun.ammo = last_gun.ammo
	next_gun.xp = 0 if debug else last_gun.xp - last_gun.max_xp
	last_gun.queue_free()
	emit_signal("gunss_updated", $Guns.get_children())

	var level_up = LEVELUP.instance()
	world.get_node("Front").add_child(level_up)
	level_up.position = pc.global_position


func level_down(debug):
		var last_gun = $Guns.get_child(0)
		var next_gun = load(last_gun.resource_path.replace(last_gun.level, last_gun.level - 1))
		
		$Guns.add_child(next_gun)
		move_child(next_gun, 0)
		next_gun.ammo = last_gun.ammo
		next_gun.xp = 0 if debug else next_gun.max_xp + last_gun.xp
		emit_signal("gunss_updated", $Guns.get_children())

		var level_down = LEVELDOWN.instance()
		world.get_node("Front").add_child(level_down)
		level_down.position = pc.global_position



func disable():
	disabled = true
	pc.get_node("GunSprite").visible = false

func enable():
	disabled = false
	pc.get_node("GunSprite").visible = true

extends Node

const LEVELUP = preload("res://src/Effect/LevelUp.tscn")
const LEVELDOWN = preload("res://src/Effect/LevelDown.tscn")

var disabled = false #this is only because of a func in pc.ladder?

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent()

func _ready():
	set_guns_visible()

func _input(event):
	if not pc.disabled and not disabled and pc.can_input and $Guns.get_child_count() > 0:
		if pc.mm.current_state == pc.mm.states["inspect"]: return
		var active_gun = $Guns.get_child(0)
		
		if event.is_action_pressed("fire_manual"):
			active_gun.fire("manual")
		if event.is_action_pressed("fire_automatic") and active_gun.automatic:
			active_gun.fire("automatic")
		if event.is_action_released("fire_manual"):
			active_gun.release_manual_fire()
		if event.is_action_released("fire_automatic"):
			active_gun.release_auto_fire()

		if $Guns.get_child_count() > 1: #only swap if more than one gun
			if event.is_action_pressed("gun_left"):
				shift_gun("left")
			if event.is_action_pressed("gun_right"):
				shift_gun("right")

		if event.is_action_pressed("debug_level_up") and active_gun.level < active_gun.max_level:
				level_up(true)
		if event.is_action_pressed("debug_level_down") and active_gun.level != 1:
				level_down(true)


### METHODS

func shift_gun(direction):
	match direction:
		"left":
			var child_to_move = $Guns.get_child($Guns.get_child_count() - 1)
			$Guns.move_child(child_to_move, 0)
			pc.emit_signal("guns_updated", $Guns.get_children(), "shiftleft")
		"right":
			var child_to_move = $Guns.get_child(0)
			$Guns.move_child(child_to_move, $Guns.get_child_count() - 1)
			pc.emit_signal("guns_updated", $Guns.get_children(), "shiftright")
	
	set_guns_visible()
	
	
	pc.emit_signal("guns_updated", $Guns.get_children())
	#pc.emit_signal("xp_updated", $Guns.get_child(0).xp, $Guns.get_child(0).max_xp, $Guns.get_child(0).level, $Guns.get_child(0).max_level)
	am.play("gun_shift")



func level_up(debug):
	var current_gun = $Guns.get_child(0)
	var last_max_xp = current_gun.max_xp
	current_gun.level += 1
	current_gun.load_level()
	current_gun.xp = 0 if debug else current_gun.xp - last_max_xp
	get_parent().emit_signal("guns_updated", $Guns.get_children())

	var effect = LEVELUP.instantiate()
	world.get_node("Front").add_child(effect)
	effect.position = pc.global_position


func level_down(debug):
	var current_gun = $Guns.get_child(0)
	current_gun.level -= 1
	current_gun.load_level()
	current_gun.xp = 0 if debug else current_gun.xp + current_gun.max_xp
	get_parent().emit_signal("guns_updated", $Guns.get_children())

	var effect = LEVELDOWN.instantiate()
	world.get_node("Front").add_child(effect)
	effect.position = pc.global_position



func disable():
	disabled = true
	pc.get_node("GunManager").visible = false

func enable():
	disabled = false
	pc.get_node("GunManager").visible = true


### HELPERS

func set_guns_visible():
	var active_gun = $Guns.get_child(0)
	for g in $Guns.get_children():
		g.visible = false
	active_gun.visible = true

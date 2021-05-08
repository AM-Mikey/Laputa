extends Container

export var weapon_radius = 100
export var height_modifier = .5
export var starting_radians = 0.5 * PI
export var cycle_delay = 0.6
export var highlighted_scale = Vector2(2,2)
#export var texture_size = Vector2(16, 32)

var disabled = true

onready var tween = get_parent().get_node("Tween")
onready var timer = get_parent().get_node("CycleDelay")
onready var timer_half = get_parent().get_node("HalfCycle")
onready var label = get_parent().get_node("TextLayer/CenterContainer/Label")

onready var player = get_tree().get_root().get_node("World/Recruit")

func setup():
	
	#clear all children
	var weapon_sprites = get_children()
	for s in weapon_sprites: 
		s.free()
		
	yield(get_tree(), 'idle_frame')

	for w in player.weapon_array:
		var sprite = Sprite.new()
		add_child(sprite)
		sprite.texture = w.icon_texture
		sprite.name = w.resource_name
		sprite.editor_description = w.display_name

		if sprite.get_index() == 0:
			sprite.scale = highlighted_scale
			label.text = sprite.editor_description
	
	timer_half.start(0.000001) #just so it sets z indexes
	cycle_delay = 0.001
	place_buttons()
	cycle_delay = 0.6 #reset so the first one doesnt tween


func _input(event):
	if disabled != true:
		if event.is_action_pressed("weapon_left") and timer.time_left == 0:
			var weapons_size = player.weapon_array.size()
			timer.start(cycle_delay)
			timer_half.start(cycle_delay/2)
			
			var weapon_to_move = player.weapon_array.pop_back()
			player.weapon_array.push_front(weapon_to_move)
			player.weapon_array[0] = load("res://src/Weapon/%s" % player.weapon_array[0] + ".tres")
			move_child(get_child(weapons_size - 1), 0)
			
			place_buttons()
			
			var active_child = get_child(0)
			var old_child = get_child(1)
			
			label.text = active_child.editor_description
			tween.interpolate_property(old_child, "scale", old_child.scale, Vector2(1, 1), cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()
			tween.interpolate_property(active_child, "scale", active_child.scale, highlighted_scale, cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()

		if event.is_action_pressed("weapon_right") and timer.time_left == 0:
			var weapons_size = player.weapon_array.size()
			timer.start(cycle_delay)
			timer_half.start(cycle_delay/2)
			
			var weapon_to_move = player.weapon_array.pop_back()
			player.weapon_array.push_front(weapon_to_move)
			player.weapon_array[0] = load("res://src/Weapon/%s" % player.weapon_array[0] + ".tres")
			move_child(get_child(0), weapons_size - 1)
			
			place_buttons()
			
			var active_child = get_child(0)
			var old_child = get_child(weapons_size - 1)
			
			label.text = active_child.editor_description
			tween.interpolate_property(old_child, "scale", old_child.scale, Vector2(1, 1), cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()
			tween.interpolate_property(active_child, "scale", active_child.scale, highlighted_scale, cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()


func place_buttons():
	var weapon_sprites = get_children()
	if weapon_sprites.size() == 0:
		return
	var angle_offset = (2*PI)/weapon_sprites.size() #in degrees
	var angle = starting_radians #in radians

	for s in weapon_sprites:
		var pre_circle_pos = Vector2(weapon_radius, 0).rotated(angle)
		var circle_pos = Vector2(pre_circle_pos.x, (pre_circle_pos.y * height_modifier))
		set_z_index(s, angle)
		tween.interpolate_property(s, "position", s.position, circle_pos, cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()
		#sprite.position = circle_pos
		angle += angle_offset


func set_z_index(sprite, angle): #prepared to handle 8 guns
	yield(timer_half, "timeout") #wait for halfcycle to change z-index
	
	if angle == starting_radians: #zero
		sprite.set_z_index(5)
		#sprite.modulate = Color(1, 1, 1)
	elif angle > starting_radians and angle < starting_radians + .5*PI: #between zero and 1q
		sprite.set_z_index(4)
		#sprite.modulate = Color(0.75, 0.75, 0.75)
	elif angle > starting_radians + .5*PI and angle < starting_radians + 1*PI: #between 1q and half
		sprite.set_z_index(2)
		#sprite.modulate = Color(0.33, 0.33, 0.33)
	elif angle == starting_radians + 1*PI: #half
		sprite.set_z_index(1)
		#sprite.modulate = Color(0.25, 0.25, 0.25)
	elif angle > starting_radians + 1*PI and angle < starting_radians + 1.5*PI: #between half and 2q
		sprite.set_z_index(2)
		#sprite.modulate = Color(0.33, 0.33, 0.33)
	elif angle > starting_radians + 1.5*PI and angle < starting_radians + 2*PI: #between 2q and zero
		sprite.set_z_index(4)
		#sprite.modulate = Color(0.75, 0.75, 0.75)
	else: #1q or 2q
		sprite.set_z_index(3)
		#sprite.modulate = Color(0.5, 0.5, 0.5)

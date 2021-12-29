extends Container

export var weapon_radius = 100
export var height_modifier = .5
export var starting_radians = 0.5 * PI
export var cycle_delay = 0.6
export var highlighted_scale = Vector2(2,2)
#export var texture_size = Vector2(16, 32)

var disabled = false

onready var tween = get_parent().get_parent().get_node("Tween")
onready var timer = get_parent().get_parent().get_node("CycleDelay")
onready var timer_half = get_parent().get_parent().get_node("HalfCycle")

onready var pc = get_tree().get_root().get_node("World/Recruit")

onready var inventory = get_tree().get_root().get_node("World/UILayer/Inventory")

func _ready():
	#clear all children
	var weapon_sprites = get_children()
	for s in weapon_sprites: 
		s.free()
		
	yield(get_tree(), 'idle_frame')

	for g in pc.guns.get_children():
		var sprite = Sprite.new()
		add_child(sprite)
		sprite.texture = g.icon_texture
		sprite.name = g.name
		
		if pc.guns.get_children().find(g) == 0:
			sprite.scale = highlighted_scale
			inventory.header.text = g.display_name
			inventory.body.text = g.description
			
	
	timer_half.start(0.000001) #just so it sets z indexes
	cycle_delay = 0.001
	place_buttons()
	cycle_delay = 0.6 #reset so the first one doesnt tween


func _input(event):
	if not disabled:
		var gun_count = pc.guns.get_child_count()
		if event.is_action_pressed("gun_left") and timer.time_left == 0:
			
			var gun_to_move = pc.guns.get_child(gun_count - 1)
			pc.guns.move_child(gun_to_move, 0)
			move_child(get_child(gun_count - 1), 0)
			
			timer.start(cycle_delay)
			timer_half.start(cycle_delay/2)
			
			place_buttons()
			
			var active_child = get_child(0)
			var old_child = get_child(1)
			
			inventory.header.text = pc.guns.get_child(0).display_name
			inventory.body.text = pc.guns.get_child(0).description
			
			tween.interpolate_property(old_child, "scale", old_child.scale, Vector2(1, 1), cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()
			tween.interpolate_property(active_child, "scale", active_child.scale, highlighted_scale, cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()

		if event.is_action_pressed("gun_right") and timer.time_left == 0:
			var gun_to_move = pc.guns.get_child(0)
			pc.guns.move_child(gun_to_move, gun_count - 1)
			move_child(get_child(0), gun_count - 1)
			
			timer.start(cycle_delay)
			timer_half.start(cycle_delay/2)

			place_buttons()
			
			var active_child = get_child(0)
			var old_child = get_child(gun_count - 1)
			
			inventory.header.text = pc.guns.get_child(0).display_name
			inventory.body.text = pc.guns.get_child(0).description
			
			tween.interpolate_property(old_child, "scale", old_child.scale, Vector2(1, 1), cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()
			tween.interpolate_property(active_child, "scale", active_child.scale, highlighted_scale, cycle_delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()


func place_buttons():
	var weapon_sprites = get_children()
	if weapon_sprites.size() == 0:
		return
	var angle_offset = (-2*PI)/weapon_sprites.size() #in degrees
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

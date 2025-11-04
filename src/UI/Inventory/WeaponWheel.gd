extends Container

@export var weapon_radius = 100
@export var height_modifier = .5
@export var starting_radians = 0.5 * PI
@export var cycle_delay = 0.6
@export var highlighted_scale = Vector2(2,2)
#export var texture_size = Vector2(16, 32)

@onready var timer = get_parent().get_parent().get_node("CycleDelay")
@onready var timer_half = get_parent().get_parent().get_node("HalfCycle")

@onready var pc = get_tree().get_root().get_node("World/Juniper")

@onready var inventory = get_tree().get_root().get_node("World/UILayer/UIGroup/Inventory")

func _ready():
	#clear all children
	var weapon_sprites = get_children()
	for s in weapon_sprites:
		s.free()

	await get_tree().process_frame

	for g in pc.guns.get_children():
		var sprite = Sprite2D.new()
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
	if pc.disabled or not pc.can_input:
		return
	var gun_count = pc.guns.get_child_count()
	if (event.is_action_pressed("gun_left") and timer.time_left == 0) or (event.is_action_pressed("gun_right") and timer.time_left == 0):

		var old_child = get_child(0)
		var gun_to_move

		if event.is_action_pressed("gun_left"):
			gun_to_move = pc.guns.get_child(gun_count - 1)
			pc.guns.move_child(gun_to_move, 0)
			move_child(get_child(gun_count - 1), 0)
		elif event.is_action_pressed("gun_right"):
			gun_to_move = pc.guns.get_child(0)
			pc.guns.move_child(gun_to_move, gun_count - 1)
			move_child(get_child(0), gun_count - 1)

		var active_child = get_child(0)
		timer.start(cycle_delay)
		timer_half.start(cycle_delay / 2.0)
		place_buttons()
		inventory.header.text = pc.guns.get_child(0).display_name
		inventory.body.text = pc.guns.get_child(0).description

		var tween = get_tree().create_tween()
		tween.tween_property(old_child, "scale", Vector2.ONE, cycle_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var tween2 = get_tree().create_tween()
		tween2.tween_property(active_child, "scale", highlighted_scale, cycle_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func place_buttons():
	var weapon_sprites = get_children()
	if weapon_sprites.size() == 0:
		return
	var angle_offset = (-2*PI)/weapon_sprites.size() #in degrees
	var angle = starting_radians #in radians

	for s in weapon_sprites:
		var pre_circle_pos = Vector2(weapon_radius, 0).rotated(angle)
		var circle_pos = Vector2(pre_circle_pos.x, (pre_circle_pos.y * height_modifier))
		order_z_index(s, angle)

		var tween = get_tree().create_tween()
		tween.tween_property(s, "position", circle_pos, cycle_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		#sprite.position = circle_pos
		angle += angle_offset


func order_z_index(sprite, angle): #prepared to handle 8 guns
	await timer_half.timeout #wait for halfcycle to change z-index

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

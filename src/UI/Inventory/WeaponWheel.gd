extends Container

@export var weapon_radius = 100
@export var height_modifier = .5
@export var starting_radians = 0.5 * PI
@export var cycle_time = 0.6
@export var highlighted_scale = Vector2(2,2)
#export var texture_size = Vector2(16, 32)
var finished_ready = false
var has_placed_buttons = false

@onready var timer = $CycleDelay
@onready var timer_half = $HalfCycle
@onready var pc = f.pc()
@onready var inventory = owner


func _ready():
	await get_tree().process_frame
	#clear all children
	for s in $Sprites.get_children():
		s.free()

	for g in pc.guns.get_children():
		var sprite = Sprite2D.new()
		$Sprites.add_child(sprite)
		#sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		sprite.texture = g.icon_texture
		sprite.name = g.name

		if pc.guns.get_children().find(g) == 0: #gun 0 is big
			sprite.scale = highlighted_scale
			inventory.header.text = g.display_name
			inventory.body.text = g.description

	place_buttons()
	finished_ready = true


func _physics_process(_delta):
	if finished_ready:
		order_z_index()

func _input(event):
	if pc.disabled or not pc.can_input:
		return
	var gun_count = pc.guns.get_child_count()
	if (event.is_action_pressed("gun_left") || event.is_action_pressed("gun_right")) && timer.time_left == 0: # and timer.time_left == 0)
		var old_child = $Sprites.get_child(0)
		var gun_to_move

		if event.is_action_pressed("gun_left"):
			gun_to_move = pc.guns.get_child(gun_count - 1)
			pc.guns.move_child(gun_to_move, 0)
			$Sprites.move_child($Sprites.get_child(gun_count - 1), 0)
		elif event.is_action_pressed("gun_right"):
			gun_to_move = pc.guns.get_child(0)
			pc.guns.move_child(gun_to_move, gun_count - 1)
			$Sprites.move_child($Sprites.get_child(0), gun_count - 1)

		var active_child = $Sprites.get_child(0)
		timer.start(cycle_time)
		timer_half.start(cycle_time / 2.0)
		place_buttons()
		inventory.header.text = pc.guns.get_child(0).display_name
		inventory.body.text = pc.guns.get_child(0).description

		var tween = create_tween()
		tween.tween_property(old_child, "scale", Vector2.ONE, cycle_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var tween2 = create_tween()
		tween2.tween_property(active_child, "scale", highlighted_scale, cycle_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func place_buttons():
	var sprites = $Sprites.get_children()
	if sprites.size() == 0:
		return
	var angle_offset = (-2*PI)/sprites.size() #in degrees

	for s in sprites:
		var index = $Sprites.get_children().find(s)
		var angle = starting_radians + (angle_offset * index) #in radians
		var pre_circle_pos = Vector2(weapon_radius, 0).rotated(angle)
		var circle_pos = Vector2(pre_circle_pos.x, (pre_circle_pos.y * height_modifier))
		if !has_placed_buttons:
			s.position = circle_pos
		else:
			var tween = create_tween()
			tween.tween_property(s, "position", circle_pos, cycle_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	has_placed_buttons = true


func order_z_index():
	var sprites = $Sprites.get_children()
	var y_positions = {} # position: [nodes]
	for s in sprites:
		var rounded_y_pos = round(s.position.y) #this decreases accuracy
		if !y_positions.has(rounded_y_pos):
			y_positions[rounded_y_pos] = [s]
		else:
			y_positions[rounded_y_pos].append(s)

	var index = 0.0
	y_positions.sort()
	for key in y_positions:
		for value in y_positions[key]:
			if value is Array:
				for node in value:
					node.z_index = index
			else:
				value.z_index = index
		index += 1

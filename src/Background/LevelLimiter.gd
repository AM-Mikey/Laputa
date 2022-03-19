tool
extends MarginContainer



signal limit_camera(left, right, top, bottom)

export var background: StreamTexture

export(Resource) var resource

onready var world = get_tree().get_root().get_node("World")
onready var camera = get_tree().get_root().get_node_or_null("World/Juniper/PlayerCamera")

enum PxFocus {CENTER, TOP, ONE_QUARTER, THREE_QUARTERS, BOTTOM}
export(PxFocus) var px_focus

enum TileMode {BOTH, HORIZONTAL, VERTICAL, NONE}
export(TileMode) var tile_mode




func _ready():
	if Engine.editor_hint:
		pass
	else:
		pass
#		$TextureRect.queue_free()
#
#		var tr = load("res://src/Background/BackgroundTexture.tscn").instance()
#		tr.texture = background
#		tr.expand = true
#		tr.stretch_mode = TextureRect.STRETCH_TILE
#		tr.rect_scale = Vector2(float(world.resolution_scale), float(world.resolution_scale))
#		world.get_node("BackgroundLayer").add_child(tr)
	
		###################################################################################################new background resource stuff
		$TextureRect.queue_free()
		for c in world.get_node("ParallaxBackground").get_children():
			c.free()
		for c in world.get_node("BackgroundLayer").get_children():
			c.free()
		########################################################################################
		if resource != null:
			var current_layer: int = 0
			for i in resource.textures:
				var pl = ParallaxLayer.new()
				pl.motion_scale = resource.motion_scales[current_layer]
				world.get_node("ParallaxBackground").add_child(pl)

				var tr = load("res://src/Background/BackgroundTexture.tscn").instance()
				tr.texture = resource.textures[current_layer]
				
				set_px_base_offset()
				
				var background_length = 4000
				
				if tile_mode == TileMode.HORIZONTAL or tile_mode == TileMode.BOTH:
					tr.rect_size.x = background_length
				else:
					tr.rect_size.x = tr.texture.get_width()
				
				if tile_mode == TileMode.VERTICAL or tile_mode == TileMode.BOTH:
					tr.rect_size.y = background_length
				else:
					tr.rect_size.y = tr.texture.get_height()
				
				tr.rect_global_position = tr.rect_size * -0.5
				
				#tr.expand = true
				#tr.stretch_mode = TextureRect.STRETCH_TILE 						
				#tr.rect_scale = Vector2(1 / float(world.resolution_scale), 1 / float(world.resolution_scale))
				pl.add_child(tr)

	#			var np = NinePatchRect.new()
	#			np.texture = resource.textures[current_layer]
	#			np.axis_stretch_horizontal = np.AXIS_STRETCH_MODE_TILE
	#			np.axis_stretch_vertical = np.AXIS_STRETCH_MODE_TILE

				#np.rect_position = Vector2(-1000, -1000)
	#			np.rect_size = Vector2(9999, 9999)
	#			np.patch_margin_top = 80
	#			np.patch_margin_bottom = 100
	#
	#			pl.add_child(np)



				current_layer += 1
		else: ########################################################
			var tr = load("res://src/Background/BackgroundTexture.tscn").instance()
			tr.texture = background
			tr.rect_position = Vector2.ZERO
			tr.rect_scale = Vector2(float(world.resolution_scale), float(world.resolution_scale))
			tr.rect_size = get_tree().get_root().size / world.resolution_scale
			tr.mouse_filter = MOUSE_FILTER_IGNORE
			world.get_node("BackgroundLayer").add_child(tr)
	######################################################################################################
		#add_to_group("CameraLimiters")
		var _size = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
		if !camera:
			camera = get_tree().get_root().get_node_or_null("World/Juniper/PlayerCamera")
		if camera:
			var _value = connect("limit_camera", camera, "_on_limit_camera")
		on_viewport_size_changed()

func _process(_delta):
	if Engine.editor_hint:
		$TextureRect.texture = background


func on_viewport_size_changed():
	var left = margin_left
	var right = margin_right
	var top = margin_top
	var bottom = margin_bottom
	emit_signal("limit_camera", left, right, top, bottom)
	
	set_px_base_offset()

	

func setup_background():
	pass


func set_px_base_offset():
	var limiter_center = rect_global_position + (rect_size / 2)
	var limiter_far_corner = rect_global_position + rect_size
	
	match px_focus:
		PxFocus.CENTER:
			world.get_node("ParallaxBackground").scroll_base_offset = limiter_center * world.resolution_scale
		PxFocus.TOP:
			world.get_node("ParallaxBackground").scroll_base_offset = Vector2(limiter_center.x, 0) * world.resolution_scale
		PxFocus.ONE_QUARTER:
			world.get_node("ParallaxBackground").scroll_base_offset = Vector2(limiter_center.x, rect_global_position.y + (rect_size.y * .25)) * world.resolution_scale
		PxFocus.THREE_QUARTERS:
			world.get_node("ParallaxBackground").scroll_base_offset = Vector2(limiter_center.x, rect_global_position.y + (rect_size.y * .75)) * world.resolution_scale
		PxFocus.BOTTOM:
			world.get_node("ParallaxBackground").scroll_base_offset = Vector2(limiter_center.x, limiter_far_corner.y) * world.resolution_scale

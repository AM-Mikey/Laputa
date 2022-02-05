tool
class_name AutotileGenerator
extends Node2D
	
const corners = [
	Vector2(0, 0),
	Vector2(0, 0.5),
	Vector2(0.5, 0),
	Vector2(0.5, 0.5),
]
const conter_corners = [
	Vector2(0.5, 0.5),
	Vector2(0.5, 0),
	Vector2(0, 0.5),
	Vector2(0, 0),
]
const bits_3x3min = [
	16, 48, 56, 24, 187, 440, 248, 190, 432, 506, 504, 216,
	144, 176, 184, 152, 434, 510, 507, 218, 438, 254, 0, 251,
	146, 178, 186, 154, 182, 447, 255, 155, 446, 511, 443, 219,
	18, 50, 58, 26, 250, 62, 59, 442, 54, 63, 191, 27
]
const bits_2x2 = [
	325, 320, 5, 256, 
	260, 324, 261, 68, 
	65, 321, 69, 1, 
	0, 64, 257, 4
]
	
	
enum MODE {
	BITMASK_3X3
	BITMASK_3X3_MINIMAL
	BITMASK_2X2_1
	BITMASK_2X2_2
}

export(MODE) var autotile_mode = MODE.BITMASK_3X3_MINIMAL
export(Vector2) var tile_size = Vector2()
export(bool) var copy_collisions = false

var _autotile_mode = TileSet.BITMASK_3X3_MINIMAL
var _src_tiles_count = 5
var _dest_tiles_x = 12
var _dest_tiles_y = 4
var _tiles_data = {}

var _sprites = []
var _texture_offsets = []


func setup_3x3() -> void:
	_autotile_mode = TileSet.BITMASK_3X3
	_src_tiles_count = 9
	_dest_tiles_x = 16
	_dest_tiles_y = 16
	_tiles_data.clear()
	
	var corner_bits = [1,64,4,256]
	var corner_bits_x = [2,128,2,128]
	var corner_bits_y = [8,8,32,32]
	var corner_bits_xx = [4,1,1,4]
	var corner_bits_yy = [64,256,256,64]
		
	var x = 0
	var y = 0
	
	for bits in range(512):
		if (bits & 16) == 0: continue
		
		var point = Vector2(x,y)
		var data = [Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,bits]
		for corner in range(4):
			data[corner] = corners[corner]
			if (bits & corner_bits[corner]) != 0:
				if (bits & corner_bits_x[corner]) != 0 and (bits & corner_bits_y[corner]) != 0: data[corner].x += 3
				elif (bits & corner_bits_x[corner]) != 0: data[corner].x += 6
				elif (bits & corner_bits_y[corner]) != 0: data[corner].x += 7
				else: data[corner].x += 5
			else:
				if (bits & corner_bits_x[corner]) != 0 and (bits & corner_bits_y[corner]) != 0: data[corner].x += 3 
				elif (bits & corner_bits_x[corner]) != 0: data[corner].x += 1
				elif (bits & corner_bits_y[corner]) != 0: data[corner].x += 2
				elif (bits & corner_bits_xx[corner]) != 0 or (bits & corner_bits_yy[corner]) != 0: data[corner].x += 4
				else: data[corner].x += 0
		_tiles_data[point] = data
		
		x += 1
		if x >= 16:
			x = 0
			y += 1


func setup_3x3_min() -> void:
	_autotile_mode = TileSet.BITMASK_3X3_MINIMAL
	_src_tiles_count = 5
	_dest_tiles_x = 12
	_dest_tiles_y = 4
	_tiles_data.clear()
	
	var corner_bits = [1,64,4,256]
	var corner_bits_x = [2,128,2,128]
	var corner_bits_y = [8,8,32,32]
		
	for y in range(_dest_tiles_y):
		for x in range(_dest_tiles_x):
			var bits = bits_3x3min[x + y * 12]
			if bits == 0: continue
			
			var point = Vector2(x,y)
			var data = [Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,bits]
			for corner in range(4):
				data[corner] = corners[corner]
				if (bits & corner_bits_x[corner]) != 0 and (bits & corner_bits_y[corner]) != 0: 
					if (bits & corner_bits[corner]) != 0: data[corner].x += 4
					else: data[corner].x += 3 
				elif (bits & corner_bits_x[corner]) != 0: data[corner].x += 1
				elif (bits & corner_bits_y[corner]) != 0: data[corner].x += 2
			_tiles_data[point] = data


func setup_2x2_1() -> void:
	_autotile_mode = TileSet.BITMASK_2X2
	_src_tiles_count = 5
	_dest_tiles_x = 4
	_dest_tiles_y = 4
	_tiles_data.clear()
	
	var corner_bits = [1,64,4,256]
	var corner_bits_x = [4,256,1,64]
	var corner_bits_y = [64,1,256,4]
	var corner_bits_xy = [256,4,64,1]
	
	for x in range(4):
		for y in range(4):
			var bits = bits_2x2[x * 4 + y]
			if bits == 0: continue
			
			var point = Vector2(x,y)
			var data = [Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,bits]
			for corner in range(4):
				data[corner] = conter_corners[corner]
				if (bits & corner_bits[corner]) != 0:  
					if (bits & corner_bits_x[corner]) != 0 and (bits & corner_bits_y[corner]) != 0:
						if (bits & corner_bits_xy[corner]) != 0:  data[corner].x += 4
						else: data[corner].x += 3
					elif (bits & corner_bits_y[corner]) != 0: data[corner].x += 1
					elif (bits & corner_bits_x[corner]) != 0: data[corner].x += 2
				else: data[corner].x += -1
			_tiles_data[point] = data


func setup_2x2_2() -> void:
	_autotile_mode = TileSet.BITMASK_2X2
	_src_tiles_count = 5
	_dest_tiles_x = 4
	_dest_tiles_y = 4
	_tiles_data.clear()
	
	var corner_bits = [1,64,4,256]
	var corner_bits_x = [4,256,1,64]
	var corner_bits_y = [64,1,256,4]
	
	for x in range(4):
		for y in range(4):
			var bits = bits_2x2[x * 4 + y]
			
			var point = Vector2(x,y)
			var data = [Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,bits]
			for corner in range(4):
				data[corner] = corners[corner]
				if (bits & corner_bits[corner]) != 0: data[corner].x += 4
				elif (bits & corner_bits_x[corner]) != 0 and (bits & corner_bits_y[corner]) != 0: data[corner].x += 3
				elif (bits & corner_bits_y[corner]) != 0: data[corner].x += 2
				elif (bits & corner_bits_x[corner]) != 0: data[corner].x += 1
				else: data[corner].x += 0
			_tiles_data[point] = data


func create_tileset_texture(image_path:String = '') -> Texture:
	if !get_children():
		return null
	
	_sprites.clear()
	_texture_offsets.clear()
	
	match autotile_mode:
		MODE.BITMASK_2X2_1: setup_2x2_1()
		MODE.BITMASK_2X2_2: setup_2x2_2()
		MODE.BITMASK_3X3: setup_3x3()
		MODE.BITMASK_3X3_MINIMAL: setup_3x3_min()
	
	var texture_size = Vector2()
	
	for node in get_children():
		if node.visible and node is Sprite:
			_sprites.append(node)
			_texture_offsets.append(Vector2(0,texture_size.y))
			if tile_size == Vector2.ZERO:
				tile_size = Vector2(node.region_rect.size.y,node.region_rect.size.y)
			var texture_width = tile_size.x * _dest_tiles_x
			if !node.region_enabled:
				node.region_enabled = true
				node.region_rect.size = node.texture.get_size()
			if texture_width > texture_size.x:
				texture_size.x = texture_width
			texture_size.y += tile_size.y * _dest_tiles_y
	
	var tileset_image := Image.new()
	tileset_image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	
	for i in range(_sprites.size()):
		_blit_tileset_image(_sprites[i], tileset_image, _texture_offsets[i])
	
	var tileset_texture:Texture
	
	if image_path:
		tileset_image.save_png(image_path)
		print("saved image: ",image_path)
	else:
		tileset_texture = ImageTexture.new()
		tileset_texture.create_from_image(tileset_image,2)
		
	return tileset_texture


func fill_tileset(tile_set:TileSet, tileset_texture:Texture = create_tileset_texture()) -> TileSet:
	for i in range(_sprites.size()):
		_create_autotile(tile_set, _sprites[i].name, tileset_texture, _texture_offsets[i], _blit_shapes(_sprites[i]))
		
	return tile_set


func _blit_tileset_image(sprite:Sprite, tileset_image:Image, texture_offset:Vector2) -> void:
	var sprite_image: Image = sprite.texture.get_data()
	var region_tex_offset = sprite.region_rect.position
	var rect_size = tile_size/2
	
	for i in range(_tiles_data.size()):
		var dest = _tiles_data.keys()[i] * tile_size + texture_offset
		var data = _tiles_data.values()[i]
		for j in range(4):
			var src = data[j] * tile_size + region_tex_offset
			var corner_offset =  corners[j] * tile_size + dest
			tileset_image.blit_rect(sprite_image, Rect2(src,rect_size), corner_offset)


func _blit_shapes(sprite:Sprite) -> Dictionary:
	if !copy_collisions:
		return {}
	var sprite_topleft = Vector2()
	if sprite.centered:
		sprite_topleft = sprite.region_rect.size / 2
	var sprite_shapes = {}
	for node in sprite.get_children():
		if node is Area2D:
			for n in node.get_children():
				if n is CollisionPolygon2D:
					var shape_position = n.position.round() + node.position.round() + sprite_topleft.round()
					var point = ((shape_position + n.polygon[0].round()) / tile_size * 2).floor() / 2
					var fix_position = shape_position - point.floor() * tile_size 
					if autotile_mode == MODE.BITMASK_2X2_1:
						var corner = point - point.floor()
						var conter_corner = Vector2(0 if corner.x > 0 else 0.5, 0 if corner.y > 0 else 0.5)
						fix_position += (conter_corner - corner) * tile_size
#						prints(conter_corner, corner, (conter_corner - corner))
#					print(point)
					var shape = ConvexPolygonShape2D.new()
					shape.points = n.polygon
#					print(shape.points)
					for i in range(shape.points.size()):
						shape.points[i] = shape.points[i].round() + fix_position.round()
#					print(shape.points)
					sprite_shapes[point] = shape
	return sprite_shapes


func _create_autotile(tile_set:TileSet,tile_name:String, texture:Texture, texture_offset:Vector2, shapes: Dictionary = {}) -> void:
	var id = tile_set.find_tile_by_name(tile_name)
	if id != -1:
		tile_set.remove_tile(id)
	else:
		id = tile_set.get_last_unused_tile_id()
	tile_set.create_tile(id)
	tile_set.tile_set_name(id, tile_name)
	tile_set.tile_set_texture(id, texture)
	tile_set.tile_set_region(id, Rect2(texture_offset.x, texture_offset.y, tile_size.x * _dest_tiles_x, tile_size.y * _dest_tiles_y))
	tile_set.tile_set_tile_mode(id, TileSet.AUTO_TILE)
	tile_set.autotile_set_size(id, tile_size)
	tile_set.autotile_set_bitmask_mode(id, _autotile_mode)
	
	for i in range(_tiles_data.size()):
		tile_set.autotile_set_bitmask(id, _tiles_data.keys()[i], _tiles_data.values()[i][4])
	
	if copy_collisions:
		for i in range(_tiles_data.size()):
			var data = _tiles_data.values()[i]
			for j in range(4):
				var shape = shapes.get(data[j])
				if shape:
					tile_set.tile_add_shape(id, shape, Transform2D(0.0,Vector2(0,0)), false, _tiles_data.keys()[i])
	


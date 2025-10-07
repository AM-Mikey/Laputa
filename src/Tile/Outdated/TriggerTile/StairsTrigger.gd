extends TileMap

const STAIRS = preload("res://src/Trigger/Stairs.tscn")

@onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	var stairs_top_tiles = get_used_cells_by_id(0)

	for s in stairs_top_tiles:
		var left = Vector2(s.x-1, s.y)
		var bottom_left = Vector2(s.x-1, s.y+1)
		var right = Vector2(s.x+1, s.y)
		var bottom_right = Vector2(s.x+1, s.y+1)
		
		var is_stairs = false
		var half_start = false
		var angle: float
		var height: int = 0
		var length: int = 0
		var direction = Vector2(-1, 1)
		
		if get_cell_source_id(0, left) == 1:
			is_stairs = true
			angle = 26.565
			direction.x = -1
			length += 1
			left += Vector2(-1, 0)
			bottom_left += Vector2(-1, 0)

			while get_cell_source_id(0, bottom_left) == 1 or get_cell_source_id(0, left) == 1:
				if get_cell_source_id(0, bottom_left) == 1:
					height += 1
					length += 1
					left += Vector2(-1, 1)
					bottom_left += Vector2(-1, 1)
					
				if get_cell_source_id(0, left) == 1:
					length += 1
					left += Vector2(-1, 0)
					bottom_left += Vector2(-1, 0)

		if get_cell_source_id(0, right) == 1:
			is_stairs = true
			angle = 26.565
			direction.x = 1
			length += 1
			right += Vector2(1, 0)
			bottom_right += Vector2(1, 0)

			while get_cell_source_id(0, bottom_right) == 1 or get_cell_source_id(0, right) == 1:
				if get_cell_source_id(0, bottom_right) == 1:
					height += 1
					length += 1
					right += Vector2(1, 1)
					bottom_right += Vector2(1, 1)
				
				if get_cell_source_id(0, right) == 1:
					length += 1
					right += Vector2(1, 0)
					bottom_right += Vector2(1, 0)
	
		if get_cell_source_id(0, bottom_left) == 1:
			direction.x = -1
			height += 1
			length += 1
			left += Vector2(-1, 1)
			bottom_left += Vector2(-1, 1)
	
	
			if get_cell_source_id(0, bottom_left) == 1:
				is_stairs = true
				angle = 45
				height += 1
				length += 1
				left += Vector2(-1, 1)
				bottom_left += Vector2(-1, 1)
				
				while get_cell_source_id(0, bottom_left) == 1:
					height += 1
					length += 1
					left += Vector2(-1, 1)
					bottom_left += Vector2(-1, 1)
			
			if get_cell_source_id(0, left) == 1:
				is_stairs = true
				half_start = true
				angle = 26.565
				length += 1
				left += Vector2(-1, 0)
				bottom_left += Vector2(-1, 0)
				
				while get_cell_source_id(0, bottom_left) == 1 or get_cell_source_id(0, left) == 1:
					if get_cell_source_id(0, bottom_left) == 1:
						height += 1
						length += 1
						left += Vector2(-1, 1)
						bottom_left += Vector2(-1, 1)
						
					if get_cell_source_id(0, left) == 1:
						length += 1
						left += Vector2(-1, 0)
						bottom_left += Vector2(-1, 0)

		if get_cell_source_id(0, bottom_right) == 1:
			direction.x = 1
			height += 1
			length += 1
			right += Vector2(1, 1)
			bottom_right += Vector2(1, 1)
	
	
			if get_cell_source_id(0, bottom_right) == 1:
				is_stairs = true
				angle = 45
				height += 1
				length += 1
				right += Vector2(1, 1)
				bottom_right += Vector2(1, 1)
				
				while get_cell_source_id(0, bottom_right) == 1:
					height += 1
					length += 1
					right += Vector2(1, 1)
					bottom_right += Vector2(1, 1)
			
			if get_cell_source_id(0, right) == 1:
				is_stairs = true
				half_start = true
				angle = 26.565
				length += 1
				right += Vector2(1, 0)
				bottom_right += Vector2(1, 0)
				
				while get_cell_source_id(0, bottom_right) == 1 or get_cell_source_id(0, right) == 1:
					if get_cell_source_id(0, bottom_right) == 1:
						height += 1
						length += 1
						right += Vector2(1, 1)
						bottom_right += Vector2(1, 1)
						
					if get_cell_source_id(0, right) == 1:
						length += 1
						right += Vector2(1, 0)
						bottom_right += Vector2(1, 0)

	
		if is_stairs:
			#print("angle: ", angle)
			#print("height: ", height)
			#print("length: ", length)
			
			var stairs = STAIRS.instantiate()
			stairs.global_position = s * 16
			triggers.add_child(stairs)
			
			
			stairs.get_node("CollisionPolygon2D").polygon[2] += Vector2(length * 16 * direction.x, height * 16 * direction.y)
			stairs.get_node("CollisionPolygon2D").polygon[3] += Vector2(length * 16 * direction.x, height * 16 * direction.y)
			
			
			if angle == 45:
				if direction.x == -1:
					stairs.get_node("CollisionPolygon2D").polygon[2] += Vector2(-16, 0)
					stairs.get_node("CollisionPolygon2D").polygon[3] += Vector2(0, -16)
				if direction.x == 1:
					stairs.get_node("CollisionPolygon2D").polygon[2] += Vector2(0, -16)
					stairs.get_node("CollisionPolygon2D").polygon[3] += Vector2(16, 0)
	
			if angle == 26.565:
				if direction.x == -1:
					stairs.get_node("CollisionPolygon2D").polygon[0] += Vector2(-16, 0)
					if length % 2 == 0:
						stairs.get_node("CollisionPolygon2D").polygon[2] += Vector2(-16, -8)
						stairs.get_node("CollisionPolygon2D").polygon[3] += Vector2(0, -24)
					else:
						stairs.get_node("CollisionPolygon2D").polygon[2] += Vector2(-16, 0)
						stairs.get_node("CollisionPolygon2D").polygon[3] += Vector2(0, -16)
			
				if direction.x == 1:
					stairs.get_node("CollisionPolygon2D").polygon[1] += Vector2(16, 0)
					if length % 2 == 0:
						stairs.get_node("CollisionPolygon2D").polygon[2] += Vector2(0, -24)
						stairs.get_node("CollisionPolygon2D").polygon[3] += Vector2(16, -8)
					else:
						stairs.get_node("CollisionPolygon2D").polygon[2] += Vector2(0, -16)
						stairs.get_node("CollisionPolygon2D").polygon[3] += Vector2(16, 0)
				
				if half_start == true:
					stairs.position.y +=8

	visible = false

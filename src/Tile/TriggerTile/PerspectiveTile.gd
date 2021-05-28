extends TileMap

var base_id = 0

onready var bases = get_used_cells_by_id(base_id) 
onready var player = get_tree().get_root().get_node("World/Recruit")

func _ready():
	#var selection = get_used_cells()
	#perspective_bottom_right(selection)
	pass
	
func _input(event): #not great, would need to be smoother, also other issues
	
	if event.is_action("perspective"):
		var tiles = get_used_cells()
		for t in tiles:
			if get_cellv(t) != base_id:
				set_cellv(t, -1)
		
		
		print("yehaw")
		var target_pos = player.get_node("Camera2D").get_camera_position()
		var local_pos = self.to_local(target_pos)
		var map_pos = self.world_to_map(local_pos)
	
		var center_cell = get_cellv(map_pos)
		var left_cell = Vector2(map_pos.x-1, map_pos.y)
		var right_cell = Vector2(map_pos.x+1, map_pos.y)
		

		var selection_left = []
		for x in range(map_pos.x-99, map_pos.x-5):
			for y in range(map_pos.y-3, map_pos.y+3):
				var cell = Vector2(x, y)
				if get_cellv(cell) == base_id:
					selection_left.append(cell)
		perspective_right(selection_left)

		var selection_right = []
		for x in range(map_pos.x+5, map_pos.x+99):
			for y in range(map_pos.y-3, map_pos.y+3):
				var cell = Vector2(x, y)
				if get_cellv(cell) == base_id:
					selection_right.append(cell)
		perspective_left(selection_right)

		var selection_top = []
		for x in range(map_pos.x-4, map_pos.x+4):
			for y in range(map_pos.y-99, map_pos.y-4):
				var cell = Vector2(x, y)
				if get_cellv(cell) == base_id:
					selection_top.append(cell)
		perspective_bottom(selection_top)
		
		var selection_bottom = []
		for x in range(map_pos.x-4, map_pos.x+4):
			for y in range(map_pos.y+4, map_pos.y+99):
				var cell = Vector2(x, y)
				if get_cellv(cell) == base_id:
					selection_bottom.append(cell)
		perspective_top(selection_bottom)
		
		var selection_top_left = []
		for x in range(map_pos.x-99, map_pos.x-5):
			for y in range(map_pos.y-99, map_pos.y-4):
				var cell = Vector2(x, y)
				if get_cellv(cell) == base_id:
					selection_top_left.append(cell)
		perspective_bottom_right(selection_top_left)
		
		var selection_top_right = []
		for x in range(map_pos.x+5, map_pos.x+99):
			for y in range(map_pos.y-99, map_pos.y-4):
				var cell = Vector2(x, y)
				if get_cellv(cell) == base_id:
					selection_top_right.append(cell)
		perspective_bottom_left(selection_top_right)
	
		var selection_bottom_left = []
		for x in range(map_pos.x-99, map_pos.x-5):
			for y in range(map_pos.y+4, map_pos.y+99):
				var cell = Vector2(x, y)
				if get_cellv(cell) == base_id:
					selection_bottom_left.append(cell)
		perspective_top_right(selection_bottom_left)
	
		var selection_bottom_right = []
		for x in range(map_pos.x+5, map_pos.x+99):
			for y in range(map_pos.y+4, map_pos.y+99):
				var cell = Vector2(x, y)
				if get_cellv(cell) == base_id:
					selection_bottom_right.append(cell)
		perspective_top_left(selection_bottom_right)
		
		

func perspective_left(selection):
	print("left")
	for s in selection:
		var left = Vector2(s.x-1, s.y)
		if get_cellv(left) == -1:
			set_cellv(left, 1) #left normal

func perspective_right(selection):
	print("right")
	for s in selection:
		var right = Vector2(s.x+1, s.y)
		if get_cellv(right) == -1:
			set_cellv(right, 4) #right normal

func perspective_top(selection):
	print("top")
	for s in selection:
		var top = Vector2(s.x, s.y-1)
		if get_cellv(top) == -1:
			set_cellv(top, 7) #right normal
			
func perspective_bottom(selection):
	print("bottom")
	for s in selection:
		var bottom = Vector2(s.x, s.y+1)
		if get_cellv(bottom) == -1:
			set_cellv(bottom, 10) #right normal

func perspective_top_left(selection):
	print("top_left")
	for s in selection:
		var left = Vector2(s.x-1, s.y)
		var right = Vector2(s.x+1, s.y)
		var top = Vector2(s.x, s.y-1)
		var bottom = Vector2(s.x, s.y+1)
		var top_left = Vector2(s.x-1, s.y-1)
		var top_right = Vector2(s.x+1, s.y-1)
		var bottom_left = Vector2(s.x-1, s.y+1)
		var bottom_right = Vector2(s.x+1, s.y+1)

		if get_cellv(top) == -1:
			if get_cellv(right) == base_id:
				set_cellv(top, 7) #top normal
			else:
				set_cellv(top, 9) #top angle right
		
		if get_cellv(left) == -1:
			if get_cellv(bottom) == base_id:
				set_cellv(left, 1) #left normal
			else:
				set_cellv(left, 3) #left angle bottom

		if get_cellv(top_left) == -1:
			if get_cellv(top) == base_id and get_cellv(left) == base_id:
				set_cellv(top_left, 14) #inset
			if get_cellv(top) != base_id and get_cellv(left) != base_id:
				set_cellv(top_left, 13) #corner

func perspective_top_right(selection):
	print("top_right")
	for s in selection:
		var left = Vector2(s.x-1, s.y)
		var right = Vector2(s.x+1, s.y)
		var top = Vector2(s.x, s.y-1)
		var bottom = Vector2(s.x, s.y+1)
		var top_left = Vector2(s.x-1, s.y-1)
		var top_right = Vector2(s.x+1, s.y-1)
		var bottom_left = Vector2(s.x-1, s.y+1)
		var bottom_right = Vector2(s.x+1, s.y+1)

		if get_cellv(top) == -1:
			if get_cellv(left) == base_id:
				set_cellv(top, 7) #top normal
			else:
				set_cellv(top, 8) #top angle left
		
		if get_cellv(right) == -1:
			if get_cellv(bottom) == base_id:
				set_cellv(right, 4) #right normal
			else:
				set_cellv(right, 6) #right angle bottom

		if get_cellv(top_right) == -1:
			if get_cellv(top) == base_id and get_cellv(right) == base_id:
				set_cellv(top_right, 16) #inset
			if get_cellv(top) != base_id and get_cellv(right) != base_id:
				set_cellv(top_right, 15) #corner

func perspective_bottom_left(selection):
	print("bottom_left")
	for s in selection:
		var left = Vector2(s.x-1, s.y)
		var right = Vector2(s.x+1, s.y)
		var top = Vector2(s.x, s.y-1)
		var bottom = Vector2(s.x, s.y+1)
		var top_left = Vector2(s.x-1, s.y-1)
		var top_right = Vector2(s.x+1, s.y-1)
		var bottom_left = Vector2(s.x-1, s.y+1)
		var bottom_right = Vector2(s.x+1, s.y+1)

		if get_cellv(bottom) == -1:
			if get_cellv(right) == base_id:
				set_cellv(bottom, 10) #bottom normal
			else:
				set_cellv(bottom, 12) #bottom angle right
		
		if get_cellv(left) == -1:
			if get_cellv(top) == base_id:
				set_cellv(left, 1) #left normal
			else:
				set_cellv(left, 2) #left angle top

		if get_cellv(bottom_left) == -1:
			if get_cellv(bottom) == base_id and get_cellv(left) == base_id:
				set_cellv(bottom_left, 18) #inset
			if get_cellv(bottom) != base_id and get_cellv(left) != base_id:
				set_cellv(bottom_left, 17) #corner

func perspective_bottom_right(selection):
	print("bottom_right")
	for s in selection:
		var left = Vector2(s.x-1, s.y)
		var right = Vector2(s.x+1, s.y)
		var top = Vector2(s.x, s.y-1)
		var bottom = Vector2(s.x, s.y+1)
		var top_left = Vector2(s.x-1, s.y-1)
		var top_right = Vector2(s.x+1, s.y-1)
		var bottom_left = Vector2(s.x-1, s.y+1)
		var bottom_right = Vector2(s.x+1, s.y+1)

		if get_cellv(bottom) == -1:
			if get_cellv(left) == base_id:
				set_cellv(bottom, 10) #bottom normal
			else:
				set_cellv(bottom, 11) #bottom angle left
		
		if get_cellv(right) == -1:
			if get_cellv(top) == base_id:
				set_cellv(right, 4) #right normal
			else:
				set_cellv(right, 5) #right angle top

		if get_cellv(bottom_right) == -1:
			if get_cellv(bottom) == base_id and get_cellv(right) == base_id:
				set_cellv(bottom_right, 20) #inset
			if get_cellv(bottom) != base_id and get_cellv(right) != base_id:
				set_cellv(bottom_right, 19) #corner

extends AutoTile


const DIRT = {
	mid = [161, 161, 161, 161, 161, 161, 162, 163],
	s = [177, 178, 179, 180],
	vine = [148, 149, 150, 151],
}

const GRASS = {
	nw = [192],
	n = [193, 194],
	ne = [195],
	sw = [208],
	s = [209, 210],
	se = [211],
	
	ne_sw = [224],
	nw_se = [225],
	
	n_sw = [226],
	n_se = [227],
	n_s = [240, 241],
	s_nw = [243],
	s_ne = [242],
	
	nw_ne = [228],
	sw_se = [244],
	s_nw_ne = [229],
	n_sw_se = [245],
	
	any_s = [209, 210, 240, 241, 243, 242, 229],
	any_n = [193, 194, 226, 227, 240, 241, 245],
	
	any_nw = [192, 225, 243, 228, 229],
	any_ne = [195, 224, 242, 228, 229],
	any_sw = [208, 224, 226, 244, 245],
	any_se = [211, 225, 227, 244, 245],
}

func _ready(): #TODO iterate through this all at once #IF a tile appears multiple times in a dict this will mess up
	for cell in farfront.get_used_cells(): #clear all grass tiles
		if get_pattern_ids(GRASS).has(farfront.get_cellv(cell)):
			farfront.set_cellv(cell, -1)
		
		
	for cell in front.get_used_cells():
		if get_pattern_ids(DIRT).has(front.get_cellv(cell)):
			pattern_dirt(cell)

	for cell in farfront.get_used_cells():
		if get_pattern_ids(GRASS).has(farfront.get_cellv(cell)):
			pattern_grass(cell)
#	for id in get_pattern_ids(DIRT):
#		for cell in front.get_used_cells_by_id(id):
#			pattern_dirt(cell)
#	for id in get_pattern_ids(GRASS):
#		for cell in farfront.get_used_cells_by_id(id):
#			pattern_grass(cell)




	queue_free()



func pattern_dirt(cell):
	current_layer = front

#	elif get_tile(cell, "north") == pattern_dirt["west"][0] and get_air(cell, "south"):
#		print("got sw")
#		layer.set_cellv(cell, get_random(pattern, "southwest"))
#	elif get_tile(cell, "north") == pattern_dirt["east"][0] and get_air(cell, "south"):
#		print("got se")
#		layer.set_cellv(cell, get_random(pattern, "southeast"))
#
#	if DIRT["mid"].has(get_tile(front, cell, "self")):
#
#	if get_air(front, cell, "south"):
	
	if is_tile(cell, DIRT.vine):
		set_random(cell, DIRT.vine)
	
	else:
		if is_npt(cell+S, DIRT):
			#front.set_cellv(cell, get_random(DIRT, "south"))
			set_random(cell, DIRT.s)
		else:
			#front.set_cellv(cell, get_random(DIRT, "mid"))
			set_random(cell, DIRT.mid)


	if is_npt(cell+N, DIRT):
		set_random(cell, GRASS.s, farfront)
		set_random(cell+N, GRASS.n, farfront)
		if is_npt(cell+W, DIRT) or not is_npt(cell+NW, DIRT):
			set_random(cell+W, GRASS.sw, farfront)
			set_random(cell+NW, GRASS.nw, farfront)
		if is_npt(cell+E, DIRT) or not is_npt(cell+NE, DIRT):
			set_random(cell+E, GRASS.se, farfront)
			set_random(cell+NE, GRASS.ne, farfront)



func pattern_grass(cell):
	current_layer = farfront

	if \
	is_tile(cell, GRASS.nw) and is_tile(cell+W, GRASS.any_n) or \
	is_tile(cell, GRASS.ne) and is_tile(cell+E, GRASS.any_n):
		set_random(cell, GRASS.nw_ne)
	if \
	is_tile(cell, GRASS.sw) and is_tile(cell+W, GRASS.any_s) or \
	is_tile(cell, GRASS.se) and is_tile(cell+E, GRASS.any_s):
		set_random(cell, GRASS.sw_se)
	
	
	if \
	is_tile(cell, GRASS.ne) and is_tile(cell+N, GRASS.any_nw) or \
	is_tile(cell, GRASS.sw) and is_tile(cell+S, GRASS.any_se):
		set_random(cell, GRASS.ne_sw)
	if \
	is_tile(cell, GRASS.nw) and is_tile(cell+N, GRASS.any_ne) or \
	is_tile(cell, GRASS.se) and is_tile(cell+S, GRASS.any_sw): #or \ #todo: if neither spawn, there is no way to get either of these states
	#is_tile(cell, GRASS.nw) and is_tile(cell+W, GRASS.any_ne)
		set_random(cell, GRASS.nw_se)
	
	
	if \
	is_tile(cell, GRASS.n) and is_tile(cell+N, GRASS.any_nw) or \
	is_tile(cell, GRASS.sw) and is_tile(cell+S, GRASS.any_s):
		set_random(cell, GRASS.n_sw)
	if \
	is_tile(cell, GRASS.n) and is_tile(cell+N, GRASS.any_ne) or \
	is_tile(cell, GRASS.se) and is_tile(cell+S, GRASS.any_s):
		set_random(cell, GRASS.n_se)
	if \
	is_tile(cell, GRASS.any_n) and is_tile(cell+N, GRASS.nw_ne) or \
	is_tile(cell, GRASS.sw_se) and is_tile(cell+S, GRASS.any_s):
		set_random(cell, GRASS.n_sw_se)
	
	
	if \
	is_tile(cell, GRASS.s) and is_tile(cell+S, GRASS.any_sw) or \
	is_tile(cell, GRASS.nw) and is_tile(cell+N, GRASS.any_n):
		set_random(cell, GRASS.s_nw)
	if \
	is_tile(cell, GRASS.s) and is_tile(cell+S, GRASS.any_se) or \
	is_tile(cell, GRASS.ne) and (is_tile(cell+N, GRASS.any_n) or is_tile(cell+W, GRASS.any_sw) or is_tile(cell+E, GRASS.any_se)):
		set_random(cell, GRASS.s_ne)
	if \
	is_tile(cell, GRASS.any_s) and is_tile(cell+S, GRASS.sw_se) or \
	is_tile(cell, GRASS.nw_ne) and is_tile(cell+N, GRASS.any_n):
		set_random(cell, GRASS.s_nw_ne)

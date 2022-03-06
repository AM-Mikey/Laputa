tool
extends Object

var TilesetProperties = preload("res://addons/frontrider.tiledtools/loader/TilesetPropertyResource.gd")

#this method saves the files to disk.
func import_tileset(source_file:String,target_folder:String):
	
	var tileset_file = File.new()
	if not tileset_file.file_exists(source_file):
		return 
	
	tileset_file.open(source_file, File.READ)
	var data = parse_json(tileset_file.get_as_text())
	
	tileset_file.close()
	var image_path = data["image"]
	
	
	var path = source_file.split("/")
	path.invert()
	path.remove(0)
	path.invert()
	
	var res_path = path.join("/")+"/"+image_path
	var tex = ResourceLoader.load(res_path)
	
	var tileset = TileSet.new()
	var tile_width = data["tilewidth"]
	var tile_height = data["tileheight"]
	var columns = data["columns"]
	var tile_count = data["tilecount"]
	var name = data["name"]
	var spacing = data["spacing"]
	var margin = data["margin"]
	
	var raw_tile_properties = data["tiles"]
	
	var tile_properties = TilesetProperties.new()
	
	for properties in raw_tile_properties:
		tile_properties.properties[int(properties.id)] = {}
		for property in properties.properties:
			if(property["type"] == "color"):
				tile_properties.properties[int(properties.id)][property["name"]] = Color(property["value"])
			else:
				tile_properties.properties[int(properties.id)][property["name"]] = property["value"]
			pass
		pass

	var row = 0
	var column = 0
	for id in range(tile_count):
		if(column>= columns):
			column = 0
			row+=1
			pass
			
		tileset.create_tile(id)
		var region = Rect2(
			spacing*column+margin+column*tile_width,
			spacing*row+margin+row*tile_height,
			tile_width,
			tile_height
		)

		tileset.tile_set_tile_mode(id,TileSet.SINGLE_TILE)
		tileset.tile_set_texture(id,tex)
		tileset.tile_set_region(id,region)
		tileset.tile_set_name(id,str(id))
		
		column += 1
	
	ResourceSaver.save(target_folder+"/"+name+".tres",tileset)
	ResourceSaver.save(target_folder+"/"+name+"_properties.tres",tile_properties)
	
	
func get_tileset_image(tileset:TileSet,tile_size :Vector2,columns:int)-> Image:
	var ids = tileset.get_tiles_ids()
	var rows = ceil(float(ids.size())/float(columns))
	var base_image:Image = null
	
	var tex_rect = Rect2(Vector2.ZERO,tile_size)
	var current_col = 0
	var current_row = 0
	for id in ids:
		if(current_col >columns-1):
			current_col = 0
			current_row += 1
			pass
		var texture = tileset.tile_get_texture(id)
		
		var tex_data = texture.get_data()
		if base_image == null :
			base_image = Image.new()
			base_image.create(columns*tile_size.x,rows*tile_size.y,false,tex_data.get_format())
			base_image.lock()
			pass
		var tex_pos = Vector2(current_col*tile_size.x,current_row*tile_size.y)
		print(tex_pos)
		base_image.blit_rect(tex_data,tex_rect,tex_pos)
		current_col +=1
		pass
	base_image.unlock()
	return base_image
	
func get_tileset_dict(tileset:TileSet,name:String,size:Vector2,columns:int,texture:Image,properties:TilesetProperties)->Dictionary:
	var tiled_tileset = {
  "columns": columns,
  "image": name+".png",
  "name": name,
  "imageheight": texture.get_height(),
  "imagewidth": texture.get_width(),
  "spacing": 0,
  "margin": 0,
  "tiledversion": "1.7.2",
  "tilecount": tileset.get_tiles_ids().size(),
  "tileheight": size.y,
  "tilewidth": size.x,
  "type": "tileset",
  "version": "1.6"
}
	
	if(properties != null):
		var exported_properties = []

		for id in properties.properties.keys():
			var tile_properties = properties.properties[id]
			var new_properties = {
				"id":id,
				"properties":[]
			}
			
			for tile_property_name in tile_properties.keys():
				var tile_property_value = tile_properties[tile_property_name]
				var new_property =   {
					 "name": tile_property_name,
					 "value": tile_property_value
					}
				if tile_property_value is Color:
					new_property["type"] = "color"
					new_property["value"] = "#"+(tile_property_value as Color).to_html(true)
				elif tile_property_value is bool:
					new_property["type"] = "bool"
				elif tile_property_value is String:
					new_property["type"] = "string"
				elif tile_property_value == int(tile_property_value):
					new_property["type"] = "int"
					new_property["value"] = int(tile_property_value)
				elif tile_property_value is float:
					new_property["type"] = "float"
				new_properties["properties"].append(new_property)
			exported_properties.append(new_properties)
				
		if not exported_properties.empty():
			tiled_tileset["tiles"] = exported_properties
			pass
	
	return tiled_tileset


extends Sprite

signal selected(background, type)


func _ready():
	add_to_group("SpawnPoints")

### SIGNALS

func on_editor_select():
	modulate = Color.red

func on_editor_deselect():
	modulate = Color(1,1,1)


func on_pressed():
	emit_signal("selected", self, "spawn_point")

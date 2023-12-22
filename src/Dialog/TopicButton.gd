extends Button

var state = "normal"

var state_color = {
	"normal" : Color(0.964706, 0.964706, 0.964706),
	"new" : Color.CHARTREUSE,
	"old" : Color.DARK_GRAY
}


func _ready():
	#add_color_ovverride("font_color", state_color[state])
	#custom_colors/font_color = state_color[state]
	pass



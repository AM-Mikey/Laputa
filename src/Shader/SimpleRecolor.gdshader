shader_type canvas_item;

uniform vec4 color : source_color;

void fragment(){
	vec4 sprite_color = texture(TEXTURE, UV);
COLOR = vec4(color.rgb, sprite_color.a);
}
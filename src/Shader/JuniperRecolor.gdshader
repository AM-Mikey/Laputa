shader_type canvas_item;

uniform bool screen_mode = true;
uniform int num_colors;
uniform float precision : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D palette_in;
uniform sampler2D palette_out;

vec4 swap_color(vec4 color) {
	float inc = 1.0 / float(num_colors); 
	for (float i = 0.0; i < 1.0; i += inc) {
		vec2 uv = vec2(i + (inc/2.0), 0.0);
		vec4 color_in = texture(palette_in, uv);
		if (distance(color, color_in) <= precision) {
			return texture(palette_out, uv);
		}
	}
	return color;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (screen_mode) {
		color = texture(SCREEN_TEXTURE, SCREEN_UV);
	}
	COLOR = swap_color(color);
}
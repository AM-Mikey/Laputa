shader_type canvas_item;
render_mode unshaded;

uniform float cutoff: hint_range(0.0, 1.0);
uniform sampler2D mask: hint_albedo;
void fragment()
{
	float value = texture(mask, UV).r;
	if(value < cutoff) {
		COLOR = vec4(COLOR.rgb, 1.0);
	}
	else {
		COLOR = vec4(COLOR.rgb, 0.0);
	}
	
}
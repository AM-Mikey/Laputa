shader_type canvas_item;

uniform vec4 old_eyes : hint_color;
uniform vec4 new_eyes : hint_color;
uniform vec4 old_color : hint_color;
uniform vec4 new_color : hint_color;
uniform float threshold = 0.7;

void fragment(){
	vec4 out_color = texture(TEXTURE,UV);

	vec3 diff_eyes = out_color.rgb - old_eyes.rgb;

	if(abs(length(diff_eyes)) < threshold){
		out_color.rgb = new_eyes.rgb * (vec3(1.0,1.0,1.0) - diff_eyes);
	}
	COLOR = out_color;
	
	
	out_color = texture(TEXTURE,UV);

	vec3 diff = out_color.rgb - old_color.rgb;

	if(abs(length(diff)) < threshold){
		out_color.rgb = new_color.rgb * (vec3(1.0,1.0,1.0) - diff);
	}
	COLOR = out_color;
}
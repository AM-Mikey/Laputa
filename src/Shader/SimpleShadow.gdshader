shader_type canvas_item;

uniform bool top;
uniform bool left;
uniform bool right;
uniform bool bottom;
uniform bool topleft;
uniform bool topright;
uniform bool bottomleft;
uniform bool bottomright;
uniform vec4 color  : source_color = vec4(1.0);
uniform bool inside = false;

bool check(sampler2D sampler, vec2 uv, vec2 pixel_size, vec2 offset, bool _inside)
{
	vec4 c1 = textureLod(sampler, uv                      , 0.0);
	vec4 c2 = textureLod(sampler, uv - offset * pixel_size, 0.0);
	vec4 c3 = textureLod(sampler, uv + offset * pixel_size, 0.0);
	if (_inside) return (c1.a > 0.0) == true && (c3.a > 0.0) == false;
	return (c1.a > 0.0) == false && (c2.a > 0.0) == true;
}

void fragment() 
{
	bool b_top         = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(+0,-1), inside) && top;
	bool b_left        = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(-1,+0), inside) && left;
	bool b_right       = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(+1,+0), inside) && right;
	bool b_bottom      = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(+0,+1), inside) && bottom;
	bool b_topleft     = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(-1,-1), inside) && topleft;
	bool b_topright    = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(+1,-1), inside) && topright;
	bool b_bottomleft  = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(-1,+1), inside) && bottomleft;
	bool b_bottomright = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(+1,+1), inside) && bottomright;
	
	if (b_top || b_left || b_right || b_bottom || b_topleft || b_topright || b_bottomleft || b_bottomright)
	{
		COLOR.rgb = color.rgb;
		COLOR.a  += (1.0 - COLOR.a) * color.a;
	}
}
/*
	Note to Self:
	This shader is meant to be used with a low-res texture that is tiled
	over a Panel control.
*/

shader_type canvas_item;

const lowp vec3 GREY_THRESH = normalize(vec3(0.35f, 0.5f, 0.35f));

uniform lowp sampler2D tex_main: source_color, filter_nearest, repeat_enable;
uniform lowp sampler2D tex_shimmer: source_color, filter_linear_mipmap, repeat_enable;
uniform lowp float shimmer_strength: hint_range(0.0f, 1.0f) = 0.5f;
uniform lowp float shimmer_speed = 0.1f;

group_uniforms Scroll;
uniform lowp vec2 scroll = vec2(0.5f, -1.0f);
uniform lowp vec2 scale = vec2(1.0f);

void vertex()
{
	UV += (0.1f * TIME * scroll);
}

void fragment() 
{
	lowp vec2 fuv = fract(UV * scale);
	
	lowp vec3 tint = textureLod(
		tex_shimmer, 
		fuv + vec2(
			(shimmer_speed * TIME) 
				+ (TEXTURE_PIXEL_SIZE.y * UV.y)
				- (TEXTURE_PIXEL_SIZE.x * UV.x), 
			0.0f
		), 
		0)
	.rgb;
	
	lowp vec4 colour = textureLod(tex_main, fuv, 0);
	lowp float grey = dot(colour.rgb, GREY_THRESH);
	
	colour.rgb = mix(
		colour.rgb,
		grey * tint,
		shimmer_strength
	);
	
	COLOR = vec4(colour.rgb, colour.a * COLOR.a);
}

shader_type canvas_item;

#include "res://Modules/SCHLibGD/shaders/utils.gdshaderinc"

uniform lowp sampler2D tex_screen: hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform lowp float blur_level: hint_range(1.0f, 8.0f) = 3.0f;

group_uniforms Tinting;
uniform lowp vec4 tint: source_color = vec4(1.0f);
uniform lowp float tint_fac: hint_range(0.0f, 1.0f) = 0.5f;

group_uniforms Contrast;
uniform lowp float saturate_mod: hint_range(0.0f, 2.0f) = 1.35f;

void fragment()
{
	lowp vec3 bg = textureLod(tex_screen, SCREEN_UV, blur_level).rgb;
	lowp float m = clamp(COLOR.r * COLOR.a, 0.0f, 1.0f);

	lowp vec3 final_colour = rgb2hsv(mix(bg * m, tint.rgb * m, tint_fac));
	final_colour.y *= saturate_mod;
	
	COLOR = vec4(hsv2rgb(final_colour), COLOR.a);
}
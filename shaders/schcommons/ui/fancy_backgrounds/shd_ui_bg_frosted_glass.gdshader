shader_type canvas_item;

uniform lowp sampler2D tex_screen: hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform lowp float blur_level: hint_range(1.0f, 8.0f) = 3.0f;

void fragment()
{
	lowp vec3 bg = textureLod(tex_screen, SCREEN_UV, blur_level).rgb;
	lowp float m = clamp(COLOR.r * COLOR.a, 0.0f, 1.0f);

	COLOR = vec4(bg * m, COLOR.a);
}
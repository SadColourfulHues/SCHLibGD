shader_type spatial;
render_mode blend_add, cull_back, diffuse_toon, specular_toon, unshaded, shadows_disabled, fog_disabled, depth_draw_opaque;

uniform lowp sampler2D tex_main : source_color, filter_linear_mipmap, repeat_disable;
uniform lowp float glow_intensity: hint_range(1.0f, 100.0f) = 1.0f;
uniform lowp float alpha_mod: hint_range(0.0f, 2.0f) = 1.0f;

void fragment()
{
	lowp vec4 colour = textureLod(tex_main, UV, 0);
	ALBEDO = (colour.rgb * COLOR.rgb) * glow_intensity;
	ALPHA = clamp(COLOR.a * colour.r * alpha_mod, 0.0f, 1.0f);
}

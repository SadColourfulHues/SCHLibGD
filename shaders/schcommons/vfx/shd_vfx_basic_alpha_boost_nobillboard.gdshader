shader_type spatial;
render_mode blend_mix, cull_back, diffuse_toon, specular_toon, unshaded, shadows_disabled, depth_prepass_alpha, depth_draw_opaque;

uniform lowp sampler2D tex_main : source_color, filter_linear_mipmap, repeat_disable;
uniform lowp float alpha_mod: hint_range(0.0f, 2.0f) = 1.0f;

void fragment()
{
	lowp vec4 colour = textureLod(tex_main, UV, 0);

	// Our particles use a pure black BG, so
	// we'll use the entire texture as an alpha mask
	ALBEDO = colour.rgb * COLOR.rgb;
	ALPHA = clamp(colour.r, 0.0f, 1.0f) * alpha_mod * COLOR.a;
}

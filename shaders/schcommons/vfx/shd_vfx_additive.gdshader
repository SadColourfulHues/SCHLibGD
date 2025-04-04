shader_type spatial;
render_mode blend_add, cull_back, diffuse_toon, specular_toon, unshaded, shadows_disabled, depth_draw_opaque;

uniform lowp sampler2D tex_main : source_color, filter_linear_mipmap, repeat_disable;
uniform lowp float glow_intensity: hint_range(1.0f, 100.0f) = 1.0f;
uniform lowp float alpha_mod: hint_range(0.0f, 2.0f) = 1.0f;

void vertex()
{
	// Billboard Mode: Particles
	mat4 mat_world = mat4(
			normalize(INV_VIEW_MATRIX[0]),
			normalize(INV_VIEW_MATRIX[1]),
			normalize(INV_VIEW_MATRIX[2]),
			MODEL_MATRIX[3]);

	mat_world = mat_world * mat4(
			vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
			vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
			vec4(0.0, 0.0, 1.0, 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));

	// Billboard Keep Scale: Enabled
	MODELVIEW_MATRIX = (VIEW_MATRIX * mat_world) * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));

	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment()
{
	lowp vec4 colour = textureLod(tex_main, UV, 0);
	ALBEDO = (colour.rgb * COLOR.rgb) * glow_intensity;
	ALPHA = clamp(COLOR.a * colour.r * alpha_mod, 0.0f, 1.0f);
}

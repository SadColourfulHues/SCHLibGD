shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, depth_draw_opaque, cull_back, diffuse_toon, specular_disabled, shadows_disabled, unshaded;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform int particles_anim_h_frames : hint_range(1, 128);

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
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;

	// Billboard Keep Scale: Enabled
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));

	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

	float h_frames = float(particles_anim_h_frames);
	float particle_total_frames = float(particles_anim_h_frames);
	float particle_frame = floor(INSTANCE_CUSTOM.z * particle_total_frames);

	particle_frame = mod(particle_frame, particle_total_frames);

	UV /= vec2(h_frames, 1.0f);
	UV += vec2(mod(particle_frame, h_frames) / h_frames, floor((particle_frame + 0.5) / h_frames));
}

void fragment()
{
	lowp vec4 albedo_tex = textureLod(texture_albedo, UV, 0);

	ALBEDO = COLOR.rgb * albedo_tex.rgb;
	ALPHA = COLOR.a * albedo_tex.a;
}

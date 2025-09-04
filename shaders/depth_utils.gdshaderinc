vec3 get_ndc(sampler2D depth_texture, vec2 screen_uv)
{
	float depth = texture(depth_texture, screen_uv).r;

	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		return 2.0f * vec3(screen_uv, depth) - 1.0f;
	#else
		return vec3(2.0f * screen_uv - 1.0f, depth);
	#endif
}

float get_depth(vec3 ndc, mat4 inv_proj_mat)
{
	vec4 world = inv_proj_mat * vec4(ndc, 1.0f);
	return (world.xyz / world.w).z;
}

// (Proximity Fade: from Godot visual shader)
float pfade(float depth, float dist, float vertex_z)
{
	return clamp(
		1.0f - smoothstep(depth + dist, depth, vertex_z),
		0.0f, 1.0f
	);
}
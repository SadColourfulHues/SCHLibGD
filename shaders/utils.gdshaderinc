/*
	Utilities for shaders
*/

/// Creates a border mask with a specified size limit
lowp float bordermask(vec2 uv, float size)
{
	return min(1.0f, (
		step(uv.x, size) +
		step(1.0f - uv.x, size) +
		step(uv.y, size) +
		step(1.0f - uv.y, size)
	));
}

/// Creates a border mask with a specified size limit
/// (unlike the normal version, it adds a smooth fade towards the centre.)
lowp float bordermaskfade(vec2 uv, float size)
{
	return min(1.0f, (
		smoothstep(0.0f, uv.x, size) +
		smoothstep(0.0f, 1.0f - uv.x, size) +
		smoothstep(0.0f, uv.y, size) +
		smoothstep(0.0f, 1.0f - uv.y, size)
	));
}

/// Taken from 'promixity fade' in the visual shader editor
/// To get depth just use: textureLod(depth_texture, SCREEN_UV, 0).x
lowp float fade(float depth_distance, float depth, vec2 screen_uv, vec3 vertex, mat4 invproj_matrix)
{
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		lowp vec4 world_pos = invproj_matrix * vec4(2.0f * vec3(screen_uv, depth) - 1.0f, 1.0f);
	#else
		lowp vec4 world_pos = invproj_matrix * vec4(vec3(2.0f * screen_uv - 1.0f, depth), 1.0f);
	#endif

	world_pos.xyz /= world_pos.w;
	return smoothstep(world_pos.z + depth_distance, world_pos.z, vertex.z);
}

/// From: https://gist.github.com/983/e170a24ae8eba2cd174f
/// Converts HSV to RGB
lowp vec3 hsv2rgb(vec3 c) 
{
 	lowp vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	lowp vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

/// From: https://gist.github.com/983/e170a24ae8eba2cd174f
/// Converts RGB to HSV
lowp vec3 rgb2hsv(vec3 c)
{
    lowp vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    lowp vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    lowp vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    lowp float d = q.x - min(q.w, q.y);
    lowp float e = 1.0e-10;
    
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
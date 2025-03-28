/*
	Utilities for shaders
*/

// Creates a border mask with a specified size limit
lowp float bordermask(vec2 uv, float size)
{
	return min(1.0f, (
		step(uv.x, size) +
		step(1.0f - uv.x, size) +
		step(uv.y, size) +
		step(1.0f - uv.y, size)
	));
}

// Creates a border mask with a specified size limit
// (unlike the normal version, it adds a smooth fade towards the centre.)
lowp float bordermaskfade(vec2 uv, float size)
{
	return min(1.0f, (
		smoothstep(0.0f, uv.x, size) +
		smoothstep(0.0f, 1.0f - uv.x, size) +
		smoothstep(0.0f, uv.y, size) +
		smoothstep(0.0f, 1.0f - uv.y, size)
	));
}
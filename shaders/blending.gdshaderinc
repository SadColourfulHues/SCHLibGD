/*
	*** Blending Modes ***
	From https://godotshaders.com
*/

lowp vec3 blend_screen(vec3 base, vec3 blend) {
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

lowp vec3 blend_darken(vec3 base, vec3 blend) {
	return min(base, blend);
}

lowp vec3 blend_lighten(vec3 base, vec3 blend) {
	return max(base, blend);
}

lowp vec3 blend_difference(vec3 base, vec3 blend) {
	return abs(base - blend);
}

lowp vec3 blend_exclusion(vec3 base, vec3 blend) {
	return base + blend - 2.0 * base * blend;
}

lowp vec3 blend_overlay(vec3 base, vec3 blend)
{
	vec3 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

lowp vec3 blend_hardlight(vec3 base, vec3 blend)
{
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

lowp vec3 blend_softlight(vec3 base, vec3 blend)
{
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

lowp vec3 blend_colour_dodge(vec3 base, vec3 blend) {
	return base / (1.0 - blend);
}

lowp vec3 blend_linear_dodge(vec3 base, vec3 blend) {
	return base + blend;
}

lowp vec3 blend_colour_burn(vec3 base, vec3 blend) {
	return 1.0 - (1.0 - base) / blend;
}

lowp vec3 blend_linear_burn (vec3 base, vec3 blend) {
	return base + blend - 1.0;
}


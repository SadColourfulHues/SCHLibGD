/*
	Note to Self:
	This shader uses the source image itself as a mask,
	which means that shadows are a no-no.

	Black = Borders / Big Refraction
	White = Main / Lesser Refraction
*/

shader_type canvas_item;
render_mode world_vertex_coords;

const lowp float BORDER_REF_FAC = 1.5f;

#include "res://Modules/SCHLibGD/shaders/utils.gdshaderinc"

uniform lowp sampler2D tex_screen: hint_screen_texture, filter_linear_mipmap, repeat_enable;

group_uniforms Blur;
uniform lowp float blur_level_main: hint_range(0.0f, 8.0f) = 0.5f;
uniform lowp float blur_level_borders: hint_range(0.0f, 8.0f) = 0.0f;

group_uniforms Refraction;
uniform lowp float refract_amount: hint_range(-1.0f, 1.0f) = 0.25f;
uniform lowp float border: hint_range(0.002f, 0.3f) = 0.025f;

group_uniforms Tint;
uniform lowp vec4 tint_main: source_color = vec4(1.0f);
uniform lowp vec4 tint_borders: source_color = vec4(1.0f);
uniform lowp float tint_main_fac: hint_range(0.0f, 1.0f) = 0.5f;
uniform lowp float tint_borders_fac: hint_range(0.0f, 1.0f) = 0.0f;

varying vec2 normal;

void vertex()
{
	normal = 2.0f * normalize(VERTEX) - vec2(1.0f);
}

void fragment()
{
	lowp vec2 suv = SCREEN_UV;
	lowp float edges = bordermaskfade(UV, border);
	lowp float mask = refract_amount * edges;

	// Main View //
	lowp vec2 uv = suv;
	uv.x -= mask * normal.x;
	uv.y -= mask * normal.y;

	// Refractive Border //
	lowp vec2 uv2 = suv;
	uv2.x += (BORDER_REF_FAC * mask) * normal.x;
	uv2.y += (BORDER_REF_FAC * mask) * normal.y;

	lowp vec3 bg = textureLod(tex_screen, uv, blur_level_main).rgb;
	lowp vec3 bg_alt = textureLod(tex_screen, uv2, blur_level_borders).rgb;

	lowp float blend_fac = clamp(max(0.0f, COLOR.r - smoothstep(0.9f, edges, 0.9f)) * COLOR.a, 0.0f, 1.0f);

	COLOR = vec4(
		(mix(bg_alt, tint_borders.rgb, tint_borders_fac) * (1.0f - blend_fac)) +
		(mix(bg, tint_main.rgb, tint_main_fac) * blend_fac),
		COLOR.a
	);
}
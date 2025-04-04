shader_type canvas_item;

uniform lowp float fac: hint_range(0.0, 1.0) = 0.5f;
uniform lowp float delta_fac: hint_range(0.0, 1.0) = 0.5f;
uniform lowp vec4 colour_bg : source_color = vec4(1.0f);
uniform lowp vec4 colour_fg : source_color = vec4(1.0f);
uniform lowp vec4 colour_delta: source_color = vec4(1.0f);

void fragment()
{
	lowp vec2 uv = UV;
	lowp float shade = clamp(smoothstep(0.09f, UV.y, 0.5f), 0.7f, 1.0f);

	COLOR = mix(
		mix(colour_bg, colour_delta * (1.5f + 0.5f * sin(24.0f * TIME)), step(uv.x, delta_fac)),
		colour_fg * shade,
		step(uv.x, fac)
	);
}
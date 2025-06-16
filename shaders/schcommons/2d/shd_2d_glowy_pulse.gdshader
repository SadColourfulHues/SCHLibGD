shader_type canvas_item;

uniform lowp float intensity = 1.0f;

group_uniforms Pulse;
uniform lowp float pulse_speed = 1.0f;
uniform lowp float pulse_strength = 1.0f;

void fragment()
{
	COLOR = vec4(
		COLOR.rgb * (intensity + (pulse_strength 
			* (0.5f + 0.5f * sin(pulse_speed * TIME)))), 
		COLOR.a
	);
}

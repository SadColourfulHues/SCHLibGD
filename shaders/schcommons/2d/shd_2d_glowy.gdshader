shader_type canvas_item;

uniform lowp float intensity = 1.0f;

void fragment()
{
	COLOR = vec4(COLOR.rgb * intensity, COLOR.a);
}

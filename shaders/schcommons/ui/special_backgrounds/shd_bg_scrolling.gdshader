/*
	Note to Self:
	This shader is meant to be used with a low-res texture that is tiled
	over a Panel control.
*/

shader_type canvas_item;

uniform lowp sampler2D tex_main: source_color, filter_nearest, repeat_enable;
uniform lowp vec2 scroll = vec2(0.5f, -1.0f);
uniform lowp vec2 scale = vec2(1.0f);

void vertex()
{
	UV += (0.1f * TIME * scroll);
}

void fragment() 
{
	COLOR = textureLod(tex_main, fract(UV * scale), 0);
}

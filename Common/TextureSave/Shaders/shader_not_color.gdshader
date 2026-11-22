shader_type canvas_item;

uniform vec4 color: source_color;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (tex.a == 0.0) {
		COLOR = tex;

	} else if (tex == color) {
		COLOR.a = 0.0;
	}
}
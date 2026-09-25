shader_type spatial;

uniform sampler2D subview_image: source_color;

void fragment() {
	ALBEDO = texture(subview_image, UV).rgb;
}

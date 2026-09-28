shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float falloff_power : hint_range(0.1, 4.0) = 1.0;

void fragment() {
	float radial = 1.0 - length(UV - vec2(0.5));
	radial = clamp(radial, 0.0, 1.0);
	float mask = pow(radial, falloff_power);
	ALBEDO = flash_color.rgb;
	ALPHA = mask;
	EMISSION = ALBEDO * 4.0 * mask;
}

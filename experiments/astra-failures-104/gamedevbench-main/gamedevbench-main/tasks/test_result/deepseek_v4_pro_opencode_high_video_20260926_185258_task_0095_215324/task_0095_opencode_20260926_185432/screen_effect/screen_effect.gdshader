shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

const float CURVATURE = 7.0;
const float VIGNETTE_MULTIPLIER = 2.0;

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
	vec2 warped_uv = centered_uv / (1.0 + CURVATURE * dot(centered_uv, centered_uv));
	warped_uv = (warped_uv + 1.0) * 0.5;

	float cutoff = step(0.0, warped_uv.x) * step(warped_uv.x, 1.0) * step(0.0, warped_uv.y) * step(warped_uv.y, 1.0);

	float scanline = sin((SCREEN_UV.y - mod(SCREEN_UV.y, 0.0025)) * 10000.0) * 0.25 + 0.75;

	float vignette = 1.0 - VIGNETTE_MULTIPLIER * dot(centered_uv, centered_uv);
	vignette = clamp(vignette, 0.0, 1.0);

	vec4 color = texture(screen_texture, warped_uv, 1.5) * cutoff;
	color.rgb *= scanline * vignette;

	COLOR = vec4(color.rgb, 1.0);
}
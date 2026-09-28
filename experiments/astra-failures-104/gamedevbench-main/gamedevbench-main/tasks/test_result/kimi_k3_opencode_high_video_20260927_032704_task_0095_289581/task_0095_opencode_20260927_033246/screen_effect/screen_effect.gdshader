shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

const float curvature = 7.0;
const float vignette_multiplier = 2.0;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// Centered UVs in the range [-1, 1] relative to the screen center
	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;

	// Warp UVs to simulate CRT screen curvature
	vec2 uv_offset = centered_uv.yx / curvature;
	vec2 warped_uv = centered_uv + centered_uv * uv_offset * uv_offset;

	// Cutoff mask: black outside of the curved screen bounds
	vec3 cutoff = vec3(step(abs(warped_uv.x), 0.5) * step(abs(warped_uv.y), 0.5));

	// Scanlines
	vec3 scanlines = vec3(sin(2.0 * warped_uv.y * 100.0) * 0.1 + 0.9);

	// Vignette: darken towards the edges of the curved screen
	vec3 vignette = vec3(length(pow(abs(warped_uv), vec2(4.0)) / 0.5));

	// Sample the screen back through the warped UVs, with a small LOD bias to blur
	vec2 screen_uv = (warped_uv + 1.0) / 2.0;
	vec3 color = cutoff * scanlines * textureLod(screen_texture, screen_uv, 0.25).rgb * (1.0 - vignette * vignette_multiplier);

	COLOR = vec4(color, 1.0);
}

shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

const float curvature = 7.0;
const float vignette_multiplier = 2.0;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
    vec2 warped_uv = centered_uv * (1.0 + dot(centered_uv, centered_uv) / curvature);
    vec2 screen_uv = warped_uv * 0.5 + 0.5;

    float cutoff = 1.0 - step(1.0, max(abs(warped_uv.x), abs(warped_uv.y)));
    vec2 clamped_uv = clamp(screen_uv, vec2(0.0), vec2(1.0));

    float scanline = 0.94 + 0.06 * sin(clamped_uv.y / SCREEN_PIXEL_SIZE.y * PI);

    vec2 vignette_uv = clamped_uv * (1.0 - clamped_uv);
    float vignette = pow(16.0 * vignette_uv.x * vignette_uv.y, vignette_multiplier);

    vec4 screen_color = textureLod(screen_texture, clamped_uv, 0.5);
    COLOR = vec4(screen_color.rgb * cutoff * scanline * vignette, 1.0);
}

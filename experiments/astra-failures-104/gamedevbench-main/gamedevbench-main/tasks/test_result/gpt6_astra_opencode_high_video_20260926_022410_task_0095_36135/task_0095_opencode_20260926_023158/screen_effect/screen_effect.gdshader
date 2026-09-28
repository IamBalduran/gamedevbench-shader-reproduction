shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

const float curvature = 7.0;
const float vignette_multiplier = 2.0;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 centered_uv = SCREEN_UV - vec2(0.5);
    vec2 warped_uv = centered_uv * 2.0;

    // Bend the screen more strongly towards its corners.
    warped_uv *= 1.0 + (warped_uv.yx * warped_uv.yx) / curvature;
    warped_uv = warped_uv * 0.5 + vec2(0.5);

    float screen_mask = step(0.0, warped_uv.x)
        * step(0.0, warped_uv.y)
        * step(warped_uv.x, 1.0)
        * step(warped_uv.y, 1.0);

    vec2 sample_uv = clamp(warped_uv, vec2(0.0), vec2(1.0));
    vec3 screen_color = textureLod(screen_texture, sample_uv, 0.5).rgb;

    float scanlines = 0.92 + 0.08 * sin(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y * 3.14159265);
    float vignette = 1.0 - vignette_multiplier * dot(centered_uv, centered_uv) * 0.25;
    vignette = clamp(vignette, 0.0, 1.0);

    screen_color *= scanlines * vignette * screen_mask;
    COLOR = vec4(screen_color, 1.0);
}

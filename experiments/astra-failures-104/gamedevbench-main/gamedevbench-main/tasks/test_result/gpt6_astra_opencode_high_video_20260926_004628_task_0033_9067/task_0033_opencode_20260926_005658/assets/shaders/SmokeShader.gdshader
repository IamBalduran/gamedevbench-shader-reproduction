shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D GradientFalloff;
uniform sampler3D NoiseTexture;
uniform float NoiseTexturePower : hint_range(0,1.0) = 0.5;
uniform float NoiseTextureSoftness : hint_range(0,0.5) = 0.2;
uniform vec3 ColorTint : source_color;
uniform float AlphaCutoff : hint_range(0,1) = 0.5;
uniform float TimeScale;
uniform float NoiseScale;
uniform float EmissionPower;
uniform float EmissionAlphaPower;
uniform float DisplacementScale;

varying vec3 world_position;


void vertex(){
	// Face the camera while retaining the particle's size and sprite rotation.
	float angle = INSTANCE_CUSTOM.x;
	float c = cos(angle);
	float s = sin(angle);
	mat4 sprite_rotation = mat4(vec4(c, s, 0.0, 0.0), vec4(-s, c, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mat4 particle_scale = mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	mat4 particle_model = billboard * sprite_rotation * particle_scale;
	MODELVIEW_MATRIX = VIEW_MATRIX * particle_model;
	MODELVIEW_NORMAL_MATRIX = mat3(VIEW_MATRIX * billboard * sprite_rotation);
	world_position = (particle_model * vec4(VERTEX, 1.0)).xyz;
	world_position.y += TIME * TimeScale;
	world_position *= NoiseScale;
	
	float displacement = texture(NoiseTexture, world_position).r * DisplacementScale;
	VERTEX += NORMAL * (displacement - (DisplacementScale / 2.0));
}

void fragment() {	
	//ALBEDO = texture(GradientFalloff, UV).rgb;
	vec3 noise_texture = texture(NoiseTexture, world_position).rgb;
	
	float TextureAlpha = smoothstep(NoiseTextureSoftness,1.0 - NoiseTextureSoftness, pow(NoiseTexturePower, noise_texture.r));
	
	ALBEDO = mix(ColorTint, COLOR.rgb, TextureAlpha);
	BACKLIGHT = vec3(1.0);
	ALPHA = COLOR.a * (noise_texture.r + 0.5) * texture(GradientFalloff, UV).r;
	EMISSION = COLOR.rgb * ((EmissionPower * noise_texture.r) * pow(texture(GradientFalloff, UV).r, EmissionAlphaPower) * COLOR.a);
	ALPHA_SCISSOR_THRESHOLD = AlphaCutoff;
}

// Credit to GDQuest - Godot Shader Secrets

shader_type spatial;
render_mode ambient_light_disabled;

uniform float xray_color_intensity = 1.0;
uniform float outline_sharpness = 2.0;
uniform vec4 outline_color : hint_color = vec4(1.0);

void fragment() {
	float fresnel_dot = 1.0 - dot(NORMAL, VIEW) * outline_sharpness;
	ALBEDO = vec3(0.0);
	EMISSION = smoothstep(0, 1, fresnel_dot) * outline_color.rgb * xray_color_intensity;
	ALPHA = smoothstep(0, 1, fresnel_dot);
}
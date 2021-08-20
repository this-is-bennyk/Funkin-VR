shader_type spatial;
render_mode unshaded;

uniform vec4 transition_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float cutoff : hint_range(0.0, 1.0);
uniform float smoothness : hint_range(0.0, 1.0);
uniform sampler2D mask : hint_albedo;

void fragment() {
	float value = texture(mask, UV).r;
	float alpha = smoothstep(cutoff, cutoff + smoothness, value * (1.0 - smoothness) + smoothness);
	ALBEDO = transition_color.rgb;
	ALPHA = alpha;
}


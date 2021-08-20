shader_type canvas_item;

uniform float cutoff : hint_range(0.0, 1.0);
uniform float smoothness : hint_range(0.0, 1.0);
uniform sampler2D mask : hint_albedo;

void fragment() {
	float value = texture(mask, UV).r;
	float alpha = smoothstep(cutoff, cutoff + smoothness, value * (1.0 - smoothness) + smoothness);
	COLOR = vec4(COLOR.rgb, alpha);
}

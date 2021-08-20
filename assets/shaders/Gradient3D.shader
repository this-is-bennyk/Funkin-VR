shader_type spatial;
render_mode unshaded;

uniform sampler2D gradient : hint_albedo;
uniform bool vertical = false;

void fragment() {
	vec4 final_color = vec4(0.0);
	
	if (vertical) {
		final_color = texture(gradient, vec2(UV.y, 0.0));
	} else {
		final_color = texture(gradient, vec2(UV.x, 0.0));
	}
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}

shader_type spatial;
render_mode unshaded;

uniform vec4 mask_color : hint_color = vec4(1.0);
uniform vec4 desired_color : hint_color = vec4(1.0);
uniform sampler2D tex : hint_albedo;

void fragment() {
	vec4 cur_color = texture(tex, UV);
	
	if (cur_color.rgb == mask_color.rgb) {
		ALBEDO = desired_color.rgb;
	} else {
		ALBEDO = cur_color.rgb;
	}
}

shader_type spatial;
render_mode unshaded;

uniform vec4 primary_color : hint_color = vec4(1.0);
uniform vec4 secondary_color : hint_color = vec4(vec3(0.0), 1.0);
uniform sampler2D map : hint_albedo;

void fragment() {
	if (texture(map, UV).r == 0.0) {
		ALBEDO = secondary_color.rgb;
		ALPHA = secondary_color.a;
	} else {
		ALBEDO = primary_color.rgb;
		ALPHA = primary_color.a;
	}
}

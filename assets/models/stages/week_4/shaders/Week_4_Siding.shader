shader_type spatial;
render_mode unshaded;

uniform vec4 color : hint_color = vec4(1.0);
uniform float time_warp = 1.0;
uniform float desired_time_warp = 5.0; // just so we don't have to look at the moving road while editing it

void vertex() {
	VERTEX.y += mod(TIME * time_warp, 1.0);
}

void fragment() {
	ALBEDO = color.rgb;
}

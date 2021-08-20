shader_type spatial;
render_mode unshaded;

uniform sampler2D road_texture : hint_albedo;
uniform sampler2D sunset_gradient : hint_albedo;
uniform vec2 road_stretch = vec2(1, 40);
uniform float time_warp = -1.0;
uniform float desired_time_warp = -5.0; // just so we know what value we want it to be in the final version

void fragment() {
	ALBEDO = texture(road_texture, UV * road_stretch + vec2(0, mod(TIME, 1) * time_warp)).rgb;
	vec4 sunset_gradient_color = texture(sunset_gradient, vec2(UV.y, 0.0));
	ALBEDO = mix(ALBEDO, sunset_gradient_color.rgb, sunset_gradient_color.a);
}

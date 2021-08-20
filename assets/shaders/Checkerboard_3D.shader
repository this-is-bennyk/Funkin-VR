shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 mask_color_1 : hint_color = vec4(1.0);
uniform vec4 desired_color_1 : hint_color = vec4(1.0);

uniform vec4 mask_color_2 : hint_color = vec4(1.0);
uniform vec4 desired_color_2 : hint_color = vec4(1.0);

uniform sampler2D tex : hint_albedo;

uniform vec2 scroll_speed = vec2(0.0);

void fragment() {
	vec4 cur_color = texture(tex, UV + (scroll_speed / 10.0 * TIME));
	
	if (cur_color.rgb == mask_color_1.rgb) {
		ALBEDO = desired_color_1.rgb;
	} else if (cur_color.rgb == mask_color_2.rgb) {
		ALBEDO = desired_color_2.rgb;
	} else {
		ALBEDO = cur_color.rgb;
	}
}

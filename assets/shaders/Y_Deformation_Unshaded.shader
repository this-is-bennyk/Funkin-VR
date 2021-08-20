shader_type spatial;
render_mode unshaded;

uniform sampler2D image : hint_albedo;
uniform float radius = 1.0;

void vertex() {
	VERTEX.y = radius * cos(VERTEX.x);
}

void fragment() {
	vec4 img_color = texture(image, vec2(UV.x, UV.y));
	ALBEDO = img_color.rgb;
	ALPHA = img_color.a;
}

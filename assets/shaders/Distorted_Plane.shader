shader_type spatial;
render_mode unshaded;

// 0 = sine, 1 = cosine
uniform int wave_type : hint_range(0, 1) = 0;
uniform float frequency = 1.0;
uniform float amplitude = 1.0;

uniform sampler2D plane_texture : hint_albedo;
uniform vec4 recolor : hint_color = vec4(1.0);

void vertex() {
	// Fuck you GLES2! You don't let me use switch statements
	if (wave_type == 0) {
		VERTEX.z += sin(VERTEX.x * frequency + TIME) * amplitude;
	}
}

void fragment() {
	vec4 new_color = texture(plane_texture, UV) * recolor;
	ALBEDO = new_color.rgb;
	ALPHA = new_color.a;
}

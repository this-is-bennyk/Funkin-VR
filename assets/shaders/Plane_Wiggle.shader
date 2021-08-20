shader_type spatial;
render_mode unshaded;

uniform float noise_scale = 1.0;
uniform float snap_fps = 24.0;
uniform sampler2D plane_tex : hint_albedo;

vec3 random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

float snap(float x, float snap) {
	return snap * round(x / snap);
}

void vertex() {
	VERTEX.xz += random3(VERTEX + vec3(snap(TIME, 1.0 / snap_fps), 0.0, 0.0)).xy * noise_scale;
}

void fragment() {
	vec4 col = texture(plane_tex, UV);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
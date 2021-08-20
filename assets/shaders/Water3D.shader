// Found this on GLSL sandbox. I really liked it, changed a few things and made it tileable.
// :)
// by David Hoskins.


// Water turbulence effect by joltz0r 2013-07-04, improved 2013-07-07


// Redefine below to see the tiling...
//#define SHOW_TILING

shader_type spatial;
render_mode unshaded;

const float TAU = 6.28318530718;
const int MAX_ITER = 5;

uniform vec2 resolution = vec2(800.0);

uniform bool using_custom_color = false;
uniform vec4 custom_color : hint_color = vec4(1.0);

void fragment() {
	float time = TIME * .5 + 23.0;
    // uv should be the 0-1 uv of texture...
    
	vec2 p = mod(UV * TAU * 2.0, TAU) - 250.0;
	
	vec2 i = vec2(p);
	float c = 1.0;
	float inten = .005;

	for (int n = 0; n < MAX_ITER; n++) 
	{
		float t = time * (1.0 - (3.5 / float(n+1)));
		i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
		c += 1.0/length(vec2(p.x / (sin(i.x+t)/inten),p.y / (cos(i.y+t)/inten)));
	}
	
	c /= float(MAX_ITER);
	c = 1.17-pow(c, 1.4);
	vec3 colour = vec3(pow(abs(c), 8.0));
	colour = clamp(colour + vec3(0.0, 0.35, 0.5), 0.0, 1.0);
	
	// Flash tile borders...
	vec2 pixel = 2.0 / resolution.xy;
	vec2 uv_copy = UV * 2.0;

	float f = floor(mod(TIME * .5, 2.0)); 	// Flash value.
	vec2 first = step(pixel, uv_copy) * f;		   	// Rule out first screen pixels and flash.
	uv_copy = step(fract(uv_copy), pixel);				// Add one line of pixels per tile.
	colour = mix(colour, vec3(1.0, 1.0, 0.0), (uv_copy.x + uv_copy.y) * first.x * first.y); // Yellow line
	
	if (using_custom_color) {
		float desat = (colour.r + colour.g + colour.b) / 3.0;
		colour = vec3(desat);
		ALBEDO = colour * custom_color.rgb;
	} else {
		ALBEDO = colour;
	}
}
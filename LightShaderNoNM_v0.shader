shader_type canvas_item;
render_mode blend_mix;

const float PI = 3.14159265358979323846;

uniform vec3 source_dir = vec3(0.5,0.5,2.0);
uniform vec4 source_color = vec4(0.5,0.0,0.5,0.0);
uniform float intensity = 1.75;
uniform float source_radius = 0.5;
uniform bool shadow_mode = false;
uniform bool is_tile = false;
uniform float tile_factor = 0.1;
vec4 digitize(vec4 color){
	float levels = 10.0;
	if (shadow_mode == true){levels = 25.0;}
	color.r = floor(color.r*levels)/levels;
	color.g = floor(color.g*levels)/levels;
	color.b = floor(color.b*levels)/levels;
	color.a = floor(color.a*levels)/levels;
	return color;
}
void fragment() {
	//vec3 source_dir = vec3(0.,0.5,0.0);
	//vec4 source_color = vec4(0.2,0.0,0.5,0.0);
	//float intensity = 1.75;
	//vec2 SIZE = intBitsToFloat(textureSize(TEXTURE,0));
	if (shadow_mode == false){
		vec3 norm_source = normalize(source_dir); // Get normalized direction of source
		vec2 ps = TEXTURE_PIXEL_SIZE;
		vec4 col = texture(TEXTURE,UV);
		//vec4 col = texture(TEXTURE, UV);
		if (col.a == 0.0){
			COLOR = vec4(0,0,0,0); //where the original texture is empty, make transparent
		}
		else{
			// calculate brightness due to normal and light angle
			float length_source = length(source_dir);
			// calculate brightness due to UV and position of source
			vec2 source_pos = vec2(source_dir.x*-1.0,source_dir.y*-1.0);
			vec2 UV_zeroed = UV-vec2(0.5,0.5);
			float UV_distance = distance(UV_zeroed,source_pos);
			//intensity/(UV_distance*UV_distance);
			// create final lighting to be added
			if (UV_distance < source_radius){
				float dist_factor = 1.0/pow(UV_distance,3);
				if (is_tile == false){
					if (dist_factor > 2.0){dist_factor = 2.0;} //we suppress saturating values on non-tile objects to avoid saturation
				}
				if (is_tile == true){
					dist_factor = dist_factor*tile_factor;
					if (dist_factor > 10.0){dist_factor = 10.0;} //we suppress saturating values on tile objects less
				}
				float color_brightness_0 = source_color.x+source_color.y+source_color.z;
				float cb_factor = color_brightness_0/6.0+0.5; //colors that are brighter to begin with will be more illuminated
				float tot_factor = cb_factor*intensity*dist_factor*(1.0-pow(UV_distance/source_radius,2))/source_dir.z;
				//if (factor > 2.0) {factor = 2.0;
				
				vec4 lighting = vec4(source_color.x*tot_factor,source_color.y*tot_factor,source_color.z*tot_factor,source_color.a*(1.0-pow(UV_distance/source_radius,8)));//*UV_distance);
				COLOR = digitize(col+lighting);
				if (COLOR.a > 1.0) {COLOR.a = 1.0;}
			}
		}
	}
	if (shadow_mode == true){
		vec3 norm_source = normalize(source_dir); // Get normalized direction of source
		vec2 ps = TEXTURE_PIXEL_SIZE;
		vec4 col = texture(TEXTURE,UV);
		vec2 source_pos = vec2(source_dir.x*-1.0,source_dir.y*-1.0);
		vec2 UV_zeroed = UV-vec2(0.5,0.5);
		float UV_distance = distance(UV_zeroed,source_pos);
		float shadow = (1.0-intensity/(UV_distance));
		if (shadow < 0.5) {shadow = 0.5}
		col.rgb = col.rgb*shadow;
		COLOR = digitize(col)
	}
}

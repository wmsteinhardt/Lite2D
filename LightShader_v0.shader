shader_type canvas_item;
render_mode blend_mix;

const float PI = 3.14159265358979323846;

uniform vec3 source_dir = vec3(0.5,0.5,2.0);
uniform float source_radius = float(0.5);
uniform vec4 source_color = vec4(0.5,0.0,0.5,0.0);
uniform float intensity = 1.75;
uniform float tile_factor = 0.1; //natural way to control relative lighting of tiles vs objects in scene
uniform bool shadow_mode = false;
uniform bool flip_x = false; // for tile orientation
uniform bool flip_y = false;
uniform bool transposed = false;
uniform bool is_tile = false;
// This shader is written for a pixel art game
// so we discretize the colors for the aesthetic
vec4 digitize(vec4 color){  
	float levels = 25.0;
	if (shadow_mode == true){levels = 25.0;}
	color.r = floor(color.r*levels)/levels;
	color.g = floor(color.g*levels)/levels;
	color.b = floor(color.b*levels)/levels;
	color.a = floor(color.a*levels)/levels;
	return color;
}
void fragment() {

	if (shadow_mode == false){
		vec3 norm_source = normalize(source_dir); // Get normalized direction of source
		vec2 ps = TEXTURE_PIXEL_SIZE;
		vec2 op = UV;
		if (flip_x == false && flip_y == false && transposed == false){op = UV;} //false false false
		if (flip_x && (flip_y == false) && (transposed == false)){op = vec2(1.0-UV.x,UV.y);} //true false false
		if (flip_y && (flip_x == false) && (transposed == false)){op = vec2(UV.x,1.0-UV.y);} // false true false
		if (flip_y && flip_x && transposed){op = vec2(1.0-UV.y,1.0-UV.x);} //true true true
		if (flip_x == false && flip_y == false && transposed) {op = vec2(UV.y,UV.x);} //false false true
		if (flip_x && flip_y == false && transposed){op = vec2(UV.y,1.0-UV.x);} //true false true
		if (flip_y && flip_x == false && transposed){op = vec2(1.0-UV.y,UV.x);} //false true true
		if (flip_x && flip_y && transposed == false){op = vec2(1.0-UV.x,1.0-UV.y);} //true true false
		vec4 col = texture(TEXTURE,op);
		vec4 normal_map = texture(NORMAL_TEXTURE,op);
		vec3 normal = (normal_map.xyz - vec3(0.5)) * 2.0; 

		if (col.a == 0.0){ //where the original texture is empty, make transparent
			COLOR = vec4(0,0,0,0); 
		}
		else{
			// calculate brightness due to normal and light angle
			float dot_source_normal = dot(source_dir,normal);
			float length_normal = length(normal);
			float length_source = length(source_dir);
			float angle = acos(dot_source_normal/(length_source));
			float angle_brightness = pow(angle/PI,3); //The higher the power, the greater the drop off
			// calculate brightness due to UV and position of source
			vec2 source_pos = vec2(source_dir.x*-1.0,source_dir.y*-1.0);
			vec2 UV_zeroed = UV-vec2(0.5,0.5);
			float UV_distance = distance(UV_zeroed,source_pos);
			// create final lighting to be added
			if (UV_distance < source_radius){
				float dist_factor = 1.0/pow(UV_distance,3);
				if (is_tile == false){
					if (dist_factor > 1.0){dist_factor = 1.0;} //we suppress saturating values on non-tile objects to avoid saturation
				}
				if (is_tile == true){
					dist_factor = dist_factor*tile_factor;
					if (dist_factor > 10.0){dist_factor = 10.0;} //we suppress saturating values on tile objects less
				}
				float color_brightness_0 = col.x+col.y+col.z;
				float cb_factor = color_brightness_0/6.0+0.5; //colors that are brighter to begin with will be more illuminated
				float tot_factor = cb_factor*angle_brightness*intensity*dist_factor*(1.0-pow(UV_distance/source_radius,4))/length_source;
				//if (factor > 2.0) {factor = 2.0;
				
				vec4 lighting = vec4(source_color.x*tot_factor,source_color.y*tot_factor,source_color.z*tot_factor,source_color.a*(1.0-pow(UV_distance/source_radius,1)));//*UV_distance);
				COLOR = digitize(col+lighting);//-lighting*(source_radius-UV_distance)));
				COLOR.a = col.a;
				if (COLOR.a > 1.0) {COLOR.a = 1.0;}

			}
			if (UV_distance >= source_radius){ // too far away, use source color.
				COLOR = col;
			}
		}
	}
	if (shadow_mode == true){
		vec3 norm_source = normalize(source_dir); // Get normalized direction of source
		vec2 ps = TEXTURE_PIXEL_SIZE;
		vec2 op = UV;
		if (flip_x == false && flip_y == false && transposed == false){op = UV;} //false false false
		if (flip_x && (flip_y == false) && (transposed == false)){op = vec2(1.0-UV.x,UV.y);} //true false false
		if (flip_y && (flip_x == false) && (transposed == false)){op = vec2(UV.x,1.0-UV.y);} // false true false
		if (flip_y && flip_x && transposed){op = vec2(1.0-UV.y,1.0-UV.x);} //true true true
		if (flip_x == false && flip_y == false && transposed) {op = vec2(UV.y,UV.x);} //false false true
		if (flip_x && flip_y == false && transposed){op = vec2(UV.y,1.0-UV.x);} //true false true
		if (flip_y && flip_x == false && transposed){op = vec2(1.0-UV.y,UV.x);} //false true true
		if (flip_x && flip_y && transposed == false){op = vec2(1.0-UV.x,1.0-UV.y);} //true true false
		vec4 col = texture(TEXTURE,op);
		vec4 normal_map =texture(NORMAL_TEXTURE,op);
		vec3 normal = (normal_map.xyz - vec3(0.5)) * 2.0; 
		float dot_source_normal = dot(source_dir,normal);
		float length_normal = length(normal);
		float length_source = length(source_dir);
		float angle = acos(dot_source_normal/(length_normal*length_source));
		float angle_brightness = angle/PI;
		vec2 source_pos = vec2(source_dir.x*-1.0,source_dir.y*-1.0);
		vec2 UV_zeroed = UV-vec2(0.5,0.5);
		float UV_distance = distance(UV_zeroed,source_pos);
		float shadow = (1.0-intensity/(angle_brightness/(source_radius-UV_distance)));
		if (shadow < 0.45) {shadow = 0.45} // the lower this number, the darker the shadow can be.
		vec3 shaded = col.rgb*shadow;
		if (UV_distance < source_radius*1.0){
			COLOR = digitize(vec4(shaded,col.a));
		}
		if (UV_distance >= source_radius*1.0){
			COLOR = col;
		}
	}
}

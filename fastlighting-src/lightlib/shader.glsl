uniform vec4 ambient_color;
uniform bool[128] light_state;
uniform vec2[128] light_pos;
uniform vec4[128] light_colors;
uniform vec4[128] light_nodraw_area;
uniform float[128] light_radius;
uniform float light_count;
uniform float nodraw_count;
vec2 screenSz = vec2(love_ScreenSize);

//Yes, I know this is complete crap.
//Shhh.

bool intersects(vec4 box, vec2 point)
{
    if (point.x >= box.x && point.x <= box.x + box.z
        && point.y >= box.y && point.y <= box.y + box.w) {
        return true;
    }
    return false;
}

bool isOccluded(vec2 screen_coords, vec2 light_pos)
{
    vec2 nrm = normalize(screen_coords - light_pos);
    vec2 point = light_pos;
    float d = distance(light_pos, screen_coords);
    bool returnVal = false;
    for (int i = 0; i < int(nodraw_count); i++) {
        vec4 box = light_nodraw_area[i];
        vec2 box_cen = vec2(box.x + (box.z / 2), box.y + (box.w / 2));
        vec2 boxdir = normalize(box_cen - light_pos);
        float dir = dot(nrm, boxdir);
		if (returnVal == false && intersects(box, light_pos)) {
			//return true;
			//The box is intersecting the light's position
			returnVal = true;
		}
		if (returnVal == false && intersects(box, screen_coords)) {
			//return true;
			//The box is intersecting our current pixel (this allows for lower quality casting)
			returnVal = true;
		}
		if (returnVal == false && dir > 0) {
			float d0 = distance(box.xy, light_pos);
			float d1 = distance(box.xy + vec2(box.z, 0), light_pos);
			float d2 = distance(box.xy + vec2(0, box.w), light_pos);
			float d3 = distance(box.xy + box.zw, light_pos);
			
			float minDist = min(d0, min(d1, min(d2, d3)));
			float maxDist = max(d0, max(d1, max(d2, d3)));
			
			if (d >= minDist) {
				for (float j = minDist; j <= maxDist; j+=4) {
					vec2 point = light_pos + (nrm * j);
					if (intersects(box, point)) {
						returnVal = true;
						break;
					}
				}
				//ABOVE: This will create a strange clipping area on the surface of the box facing the light.
				//This clipping area is a result of the shadow casting starting too early (A result of this much quicker method)
				//To counter this, I found that testing the code below for the occlusion area ONLY revealed that strange area.
				//Ideally I can reset returnVal from it to remove that strange area.
				//Note: It only works if d <= maxDist
				
				//There's a weird clipping issue. I can fix this with a wider check area.
				//This should work because of the way I check.
				
				if (d <= maxDist) {
					for (float j = d + 1; j <= maxDist; j++) {
						vec2 point = light_pos + (nrm * j);
						if (intersects(box, point)) {
							returnVal = false;
							break;
						}
					}
				}
				
			}
		}
    }
    return returnVal;
}

vec4 effect(vec4 love_color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	
	vec4 amb_base = ambient_color / 255;
	vec4 lColor = amb_base;
	vec4 texturecolor_pre = Texel(texture, texture_coords);
	vec4 love = (texturecolor_pre * love_color);
	
	for (int i = 0; i < int(light_count); i++) {
		bool state = light_state[i];
		if (state == true) {
			vec2 lightP = light_pos[i];
			vec4 lightC = light_colors[i];
			float r = light_radius[i];
			float dist = distance(lightP, screen_coords);
			if (dist <= r && isOccluded(screen_coords, lightP) == false) {
				float percentColor = 1.0 - (dist / r);
				vec4 clr = (lightC / 255) * percentColor;
				lColor = lColor + clr;
			}
		}
	}
	
	float lColorGray = (lColor.x + lColor.y + lColor.z) / 3;
	vec4 raw_mult = love * lColor;
	vec4 gray_mult = love * lColorGray;
	return mix(raw_mult * 2, gray_mult, 0.5);
}

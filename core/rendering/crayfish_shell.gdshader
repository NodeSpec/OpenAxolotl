shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
instance uniform float wetness = 0.0;
varying vec3 shell_point;
float grain(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float smooth_grain(vec3 p) {
	vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(mix(grain(i),grain(i+vec3(1,0,0)),f.x),mix(grain(i+vec3(0,1,0)),grain(i+vec3(1,1,0)),f.x),f.y),mix(mix(grain(i+vec3(0,0,1)),grain(i+vec3(1,0,1)),f.x),mix(grain(i+vec3(0,1,1)),grain(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){shell_point=VERTEX;}
void fragment(){
	float fine=smooth_grain(shell_point*220.0);
	float detail=1.0-smoothstep(.35,1.3,length(fwidth(shell_point*220.0)));
	float mottle=smooth_grain(shell_point*29.0);
	ALBEDO=COLOR.rgb*(.87+.19*mottle+(.10*(fine-.5)*detail));
	ROUGHNESS=clamp(mix(.38,.25,wetness)+.12*(fine-.5)*detail,.18,.48);
	METALLIC=.035;SPECULAR=.40;CLEARCOAT=.30;
}

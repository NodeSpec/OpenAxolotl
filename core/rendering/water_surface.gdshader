// Shared transparent water: lit ripples, depth absorption, shoreline foam and wakes.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, specular_schlick_ggx;
global uniform vec4 water_actor;
global uniform vec4 water_motion;
uniform sampler2D depth_buffer : hint_depth_texture, filter_nearest;
uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear;
uniform vec3 deep_tint : source_color = vec3(0.04,0.31,0.40);
uniform vec3 shallow_tint : source_color = vec3(0.26,0.64,0.64);
uniform vec3 foam_tint : source_color = vec3(0.87,0.96,0.97);
uniform float alpha_facing = 0.16;
uniform float alpha_grazing = 0.52;
uniform float ripple_scale = 0.8;
uniform float ripple_speed = 0.65;
uniform float wave_height = 0.075;
uniform float normal_strength = 0.19;
uniform float shore_band_share = 0.12;
uniform float shore_foam = 0.12;
uniform float shallows_depth_m = 0.35;
uniform float shallows_foam = 0.23;
uniform bool mesh_is_surface = false;
uniform vec2 flow_velocity = vec2(0.0);
uniform bool flow_uses_uv = false;
uniform float flow_exit_z = -100000.0;
uniform float turbulence = 0.0;
varying vec3 world_position;
varying vec3 world_normal;
varying float shore;
varying float top_face;

float caustic(vec2 p, float t) {
    vec2 cell=floor(p), local=fract(p);
    float first=8.0, second=8.0;
    for(int y=-1;y<=1;y++) {
        for(int x=-1;x<=1;x++) {
            vec2 neighbor=vec2(float(x),float(y));
            vec2 seed=cell+neighbor;
            vec2 phase=fract(sin(vec2(dot(seed,vec2(127.1,311.7)),dot(seed,vec2(269.5,183.3))))*43758.5453);
            vec2 center=neighbor+0.5+0.27*sin(phase*6.28318+t)-local;
            float d=dot(center,center);
            if(d<first) { second=first; first=d; }
            else { second=min(second,d); }
        }
    }
    return 1.0-smoothstep(0.025,0.14,second-first);
}

float wave(vec2 p, float t) {
    return (sin(dot(p,vec2(1.7,0.6))+t*1.1)
          +0.55*sin(dot(p,vec2(-0.9,2.3))-t*0.83)
          +0.23*sin(dot(p,vec2(3.8,2.1))+t*1.45))/1.78;
}
vec2 wave_slope(vec2 p, float t) {
    vec2 slope=vec2(
        wave(p+vec2(0.03,0.0),t)-wave(p-vec2(0.03,0.0),t),
        wave(p+vec2(0.0,0.03),t)-wave(p-vec2(0.0,0.03),t))/0.06;
    return slope+vec2(cos(dot(p,vec2(8.2,3.7))-t*2.4),cos(dot(p,vec2(-4.9,9.1))+t*1.8))*0.18;
}
void vertex() {
    vec2 face=mesh_is_surface ? UV : (UV-vec2(1.0/3.0,0.5))*vec2(3.0,2.0);
    vec2 inset=0.5-abs(face-0.5);
    shore=mesh_is_surface ? 1.0 : clamp(min(inset.x,inset.y)*2.0/shore_band_share,0.0,1.0);
    top_face=smoothstep(0.65,0.95,NORMAL.y);
    vec3 placed=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float outlet=flow_uses_uv ? smoothstep(flow_exit_z,flow_exit_z+4.0,placed.z) : 1.0;
    VERTEX.y+=top_face*shore*wave_height*outlet*wave((placed.xz-flow_velocity*TIME)*ripple_scale,TIME*ripple_speed);
    world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
    vec2 p=((flow_uses_uv ? UV : world_position.xz)-flow_velocity*TIME)*ripple_scale;
    float t=TIME*ripple_speed;
    float outlet=flow_uses_uv ? smoothstep(flow_exit_z,flow_exit_z+4.0,world_position.z) : 1.0;
    vec2 slope=wave_slope(p,t);
    if(flow_uses_uv) {
        // Match the receiving water's world-space normal phase at the join.
        slope=mix(wave_slope(world_position.xz*ripple_scale,t),slope,outlet);
        p=mix(world_position.xz*ripple_scale,p,outlet);
    }

    vec2 offset=world_position.xz-water_actor.xz;
    vec2 direction=normalize(water_motion.xz+vec2(0.0001));
    float aft=-dot(offset,direction);
    float lateral=abs(dot(offset,vec2(-direction.y,direction.x)));
    float active=water_actor.w*(1.0-smoothstep(0.15,0.7,abs(world_position.y-water_actor.y)));
    float wake=exp(-pow((lateral-aft*0.32)*7.0,2.0))*smoothstep(0.0,0.4,aft)*(1.0-smoothstep(0.5,4.0,aft))*active;
    slope+=vec2(sin(aft*14.0-t*5.0),cos(lateral*12.0-t*3.0))*wake*0.5;

    vec3 n=normalize(world_normal+vec3(-slope.x*normal_strength,0.0,-slope.y*normal_strength)*top_face);
    NORMAL=normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
    if(!FRONT_FACING) NORMAL=-NORMAL;
    float facing=clamp(abs(dot(NORMAL,normalize(VIEW))),0.0,1.0);
    float fresnel=pow(1.0-facing,5.0);

    float raw_depth=texture(depth_buffer,SCREEN_UV).r;
    vec4 behind=INV_PROJECTION_MATRIX*vec4(SCREEN_UV*2.0-1.0,raw_depth,1.0);
    float thickness=max(0.0,VERTEX.z-behind.z/behind.w);
    float absorption=1.0-exp(-thickness*0.12);
    float shallows=1.0-smoothstep(0.015,shallows_depth_m,thickness);
    float pulse=0.55+0.45*sin(dot(p,vec2(6.2,4.3))-t*2.2);
    float surf=shallows*shallows_foam*pulse*top_face;
    surf=max(surf,(1.0-shore)*shore_foam*pulse*top_face);
    if(flow_uses_uv) surf=max(surf,(1.0-outlet)*shore_foam*pulse*top_face);
    float streak=pow(0.5+0.5*sin(p.x*24.0+sin(p.y*5.0-t*4.0)),12.0);
    float foam=clamp(surf+wake*0.20+streak*turbulence*outlet*0.23,0.0,0.55);
    vec3 tint=mix(shallow_tint,deep_tint,absorption);
    ALBEDO=mix(tint,foam_tint,foam);
    ROUGHNESS=clamp(0.085+foam*0.3+turbulence*outlet*0.04,0.08,0.4);
    METALLIC=0.0;
    SPECULAR=0.5;
    ALPHA=clamp(mix(alpha_facing,0.30,absorption)+fresnel*alpha_grazing+foam*0.45,0.03,0.72);
    if(top_face>0.5 && FRONT_FACING) {
        vec2 refracted_uv=clamp(SCREEN_UV+slope*0.004*min(thickness,2.0),vec2(0.001),vec2(0.999));
        float refracted_depth=texture(depth_buffer,refracted_uv).r;
        vec4 refracted_point=INV_PROJECTION_MATRIX*vec4(refracted_uv*2.0-1.0,refracted_depth,1.0);
        if(refracted_point.z/refracted_point.w>VERTEX.z) refracted_uv=SCREEN_UV;
        vec3 transmitted=textureLod(scene_color,refracted_uv,0.0).rgb;
        // Project the light pattern onto the submerged geometry, not the surface.
        vec3 bed=(INV_VIEW_MATRIX*vec4(behind.xyz/behind.w,1.0)).xyz;
        float water_depth=max(0.0,world_position.y-bed.y);
        float focus=caustic(bed.xz*2.2+sin(bed.zx*0.7+t*0.3)*0.15,t*0.7);
        float light_pattern=(focus-0.25)*0.13*(0.55+0.45*sin(bed.x*1.4+sin(bed.z*1.2-t)))*smoothstep(0.02,0.18,water_depth)*exp(-water_depth*0.22);
        transmitted*=1.0+light_pattern;
        vec3 attenuation=exp(-vec3(0.58,0.17,0.10)*min(thickness,18.0));
        transmitted=transmitted*attenuation+deep_tint*(1.0-attenuation)*0.45;
        EMISSION=transmitted*(1.0-foam)*(1.0-fresnel);
        ALBEDO=mix(tint*0.035,foam_tint,foam);
        ALPHA=0.96;
    }
    // A submerged view should not see an opaque, brightly lit box side.
    if(top_face<0.1) ALPHA*=0.35;
}

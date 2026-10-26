shader_type sky;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float n(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void sky() {
 float h=max(EYEDIR.y,0.0);
 vec3 blue=mix(vec3(0.53,0.82,0.91),vec3(0.075,0.38,0.79),pow(h,0.45));
 vec2 p=EYEDIR.xz/max(0.12,h)*1.6;
 float cloud=n(p)*0.6+n(p*2.1)*0.27+n(p*4.5)*0.13;
 cloud=smoothstep(0.55,0.72,cloud)*smoothstep(0.02,0.18,h);
 COLOR=mix(blue,vec3(1.0,0.98,0.92),cloud*0.95);
 if (EYEDIR.y<0.0) COLOR=vec3(0.32,0.4,0.27);
}

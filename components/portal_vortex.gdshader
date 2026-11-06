shader_type canvas_item;
render_mode unshaded;
uniform float world_time = 0.0;
uniform float activity : hint_range(0.0, 1.0) = 1.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform bool reduced = false;
void fragment() {
	vec2 p = (floor(UV * vec2(40.0, 60.0)) + 0.5) / vec2(40.0, 60.0) * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float spin = a * 3.0 + r * 15.0 - world_time * 1.7;
	float flow = sin(spin + sin(a * 2.0 + world_time * 0.7) * 0.6) * 0.5 + 0.5;
	float rim = smoothstep(0.68, 0.81, r) * (1.0 - smoothstep(0.84, 0.97, r));
	float breath = reduced ? 0.8 : 0.78 + sin(world_time * 2.4) * 0.12;
	vec3 core = mix(vec3(0.025, 0.035, 0.10), vec3(0.20, 0.11, 0.36), flow * r);
	vec3 neon = mix(vec3(0.24, 0.85, 0.82), vec3(0.86, 0.25, 0.53), flow);
	vec3 color = core + neon * (rim * breath + pow(flow, 6.0) * r * 0.3);
	color += neon * pulse * (reduced ? 0.12 : 0.6);
	COLOR = vec4(color, (1.0 - smoothstep(0.92, 1.0, r)) * activity);
}

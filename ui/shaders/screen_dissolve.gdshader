shader_type canvas_item;
// Disolvencia por bloques de pixeles: progress 0 = transparente, 1 = cubierto.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float block : hint_range(2.0, 64.0) = 10.0;
uniform vec4 tint : source_color = vec4(0.043, 0.075, 0.133, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / block);
	float threshold = hash(cell) * 0.85 + UV.x * 0.15;
	float covered = step(threshold, progress * 1.15 - 0.075);
	COLOR = vec4(tint.rgb, covered * tint.a);
}

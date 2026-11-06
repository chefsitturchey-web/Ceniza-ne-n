shader_type canvas_item;
// Velo de pantalla: vineta suave y lineas de escaneo tenues. No lee la pantalla.
uniform float scanline : hint_range(0.0, 0.3) = 0.07;
uniform float vignette : hint_range(0.0, 1.0) = 0.55;
uniform float line_size = 3.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	centered.x *= 1.15;
	float edge = smoothstep(0.25, 0.85, length(centered));
	float line = step(0.5, fract(FRAGCOORD.y / line_size / 2.0)) * scanline;
	COLOR = vec4(0.02, 0.04, 0.08, clamp(edge * vignette + line, 0.0, 0.9));
}

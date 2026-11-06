shader_type canvas_item;
render_mode unshaded;
// Portal en pixel art: deja ver el fondo torcido por el remolino, con color
// escalonado y tramado (Bayer 4x4) en vez de degradados lisos.
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float world_time = 0.0;
uniform float activity : hint_range(0.0, 1.0) = 1.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform bool reduced = false;
const vec2 GRID = vec2(42.0, 58.0);

float bayer4(vec2 cell) {
	float m[16] = {0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0};
	int index = int(mod(cell.x, 4.0)) + int(mod(cell.y, 4.0)) * 4;
	return (m[index] + 0.5) / 16.0;
}

float hash(vec2 v) {
	return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * GRID);
	vec2 p = (cell + 0.5) / GRID * 2.0 - 1.0;
	float r = length(p);
	float dither = bayer4(cell);
	float a = atan(p.y, p.x);
	float t = world_time * (reduced ? 0.5 : 1.0);

	// Brazos del remolino que giran hacia el centro.
	float arms = sin(a * 3.0 + (1.0 - r) * 9.0 - t * 2.2) * 0.5 + 0.5;
	arms *= 1.0 - smoothstep(0.5, 0.88, r);
	float rim = 1.0 - smoothstep(0.0, 0.1, abs(r - 0.85));
	float rim_flow = sin(a * 5.0 - t * 3.0) * 0.5 + 0.5;
	float eye = 1.0 - smoothstep(0.0, 0.24, r);
	float breath = reduced ? 0.0 : sin(t * 2.4) * 0.08;
	float glow = rim * (0.62 + rim_flow * 0.38) + arms * 0.5 * (1.0 - eye) + eye * (0.62 + breath);
	glow += pulse * (reduced ? 0.15 : 0.55) * (1.0 - r * 0.6);

	// Fondo visto a través del portal, girado y teñido de violeta.
	float inner = 1.0 - smoothstep(0.15, 0.9, r);
	vec2 bend = vec2(-p.y, p.x) * (1.0 - r) * 0.014 * (0.5 + arms);
	vec3 behind = texture(screen_tex, SCREEN_UV + bend).rgb;
	float lum = dot(behind, vec3(0.3, 0.5, 0.2));
	vec3 deep = mix(vec3(0.035, 0.03, 0.09), vec3(0.17, 0.09, 0.28), lum * 1.4);
	vec3 color = mix(behind * vec3(0.45, 0.7, 0.95), deep, 0.5 + inner * 0.4);

	// Rampa corta de la paleta del juego, escalonada con tramado.
	float level = min(floor(clamp(glow, 0.0, 1.0) * 4.0 + dither), 4.0);
	if (level >= 4.0) color = vec3(0.86, 1.0, 0.95);
	else if (level >= 3.0) color = vec3(0.28, 0.85, 0.80);
	else if (level >= 2.0) color = vec3(0.16, 0.50, 0.58);
	else if (level >= 1.0) color = mix(color, vec3(0.36, 0.14, 0.46), 0.75);

	// Chispas sueltas dentro del remolino.
	if (!reduced && r < 0.75 && hash(cell + floor(t * 7.0)) > 0.988) color = vec3(0.86, 1.0, 0.95);

	// Borde roto en píxeles, sin difuminado.
	float alpha = r < 0.9 + dither * 0.07 ? 1.0 : 0.0;
	COLOR = vec4(color, alpha * activity);
}

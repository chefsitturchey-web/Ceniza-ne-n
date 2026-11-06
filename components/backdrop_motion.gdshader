shader_type canvas_item;
// Da vida a la capa pintada del distrito sin repintarla: una máscara por zona
// (tools/art/build_backdrop_masks.py) marca cascadas, agua, ventanas, neón, llamas,
// balizas, ventiladores, estandartes, tiras LED y metal fundido. Todo se muestrea en
// el centro de cada téxel: el resultado sigue siendo pixel art nítido, sin mezclas suaves.

uniform sampler2D motion_mask : filter_nearest;
uniform vec4 fans[2]; // centro (téxeles), radio, velocidad en rad/s
uniform float clock = 0.0; // tiempo del distrito: se detiene con la pausa
uniform float night = 0.0; // 0 día, 1 noche
uniform float steady = 0.0; // 1 con «reducir destellos»: sin apagones ni parpadeos rápidos
uniform float fall_speed = 24.0; // téxeles por segundo
uniform vec3 fall_light : source_color = vec3(0.86, 0.95, 1.0);
uniform float enabled = 1.0;

varying vec4 tint;

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float hash(float n) { return fract(sin(n * 12.9898 + 4.1414) * 43758.5453); }
float hash2(vec2 p) { return hash(p.x * 157.0 + p.y * 113.0); }
float bayer(vec2 texel) { return (BAYER[int(mod(texel.y, 4.0)) * 4 + int(mod(texel.x, 4.0))] + 0.5) / 16.0; }


float kind_at(vec2 texel, vec2 size) { return floor(texture(motion_mask, (texel + 0.5) / size).r * 255.0 / 16.0 + 0.5); }

void vertex() { tint = COLOR; }

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 texel = floor(UV * size);
	vec4 m = texture(motion_mask, (texel + 0.5) / size);
	float kind = floor(m.r * 255.0 / 16.0 + 0.5) * enabled;
	float seed = m.g * 255.0;
	float param = m.b * 255.0;
	vec4 color = texture(TEXTURE, (texel + 0.5) / size);
	float lights = mix(0.92, 1.18, night);
	if (kind == 1.0) {
		// Cascada: dos fases de desplazamiento que se alternan con trama ordenada.
		float span = max(seed, 4.0);
		float loop_len = min(18.0, span);
		float phase = clock * fall_speed / loop_len;
		float a = fract(phase);
		float b = fract(phase + 0.5);
		float use_a = step(bayer(texel + vec2(0.0, floor(clock * 6.0))), 1.0 - abs(2.0 * a - 1.0));
		float offset = floor(mix(b, a, use_a) * loop_len);
		float source = max(param - offset, 0.0);
		color = texture(TEXTURE, (vec2(texel.x, texel.y - param + source) + 0.5) / size);
		// Vetas claras que bajan a distinta velocidad por columna.
		float column = hash(texel.x + 3.0);
		float band = fract((param - clock * fall_speed * (1.15 + column * 0.6)) / (9.0 + column * 15.0) + column);
		if (band < 0.13) color.rgb = mix(color.rgb, fall_light, 0.42);
		else if (band < 0.22) color.rgb = mix(color.rgb, fall_light, 0.18);
		// Espuma viva en el pie de la caída.
		if (param > span - 5.0 && hash2(vec2(texel.x, floor(clock * 9.0) + texel.y)) > 0.45) color.rgb = mix(color.rgb, fall_light, 0.55);
	} else if (kind == 2.0) {
		// Agua: oleaje horizontal escalonado; los reflejos se rompen y brillan.
		float strength = param / 255.0;
		float wave = sin(texel.y * 0.85 + clock * 2.1 + sin(texel.x * 0.045 + clock * 0.6) * 1.6);
		float shift = floor(wave * (0.6 + strength * 1.6) + 0.5);
		vec2 source = texel + vec2(shift, 0.0);
		if (kind_at(source, size) == 2.0) color = texture(TEXTURE, (source + 0.5) / size);
		float bright = dot(color.rgb, vec3(0.3, 0.59, 0.11));
		if (bright > 0.32 && hash2(vec2(floor(texel.x / 2.0), texel.y + floor(clock * 5.0) * 7.0)) > 0.9) color.rgb += vec3(0.16, 0.2, 0.22) * strength;
	} else if (kind == 3.0) {
		// Ventanas: casi siempre encendidas; algunas se apagan un rato y titilan al volver.
		float period = 9.0 + hash(seed) * 26.0;
		float cycle = fract((clock + seed * 3.7) / period);
		float factor = lights;
		if (hash(seed + 11.0) < 0.38 && cycle < 0.22) {
			bool edge = cycle > 0.19 || cycle < 0.025;
			factor = (edge && steady < 0.5 && mod(floor(clock * 15.0), 2.0) < 1.0) ? lights : 0.42;
		}
		color.rgb *= factor;
	} else if (kind == 4.0) {
		// Neón: zumbido de baja amplitud y cortes breves muy espaciados.
		float buzz = steady > 0.5 ? 1.0 : 1.0 + 0.06 * step(0.5, hash(floor(clock * 12.0) + seed));
		if (steady < 0.5 && hash(floor(clock * 2.5) + seed * 13.0) > 0.965) buzz = 0.45;
		color.rgb *= buzz * lights;
	} else if (kind == 5.0) {
		// Llamas y velas: ruido escalonado, más lento con destellos reducidos.
		float rate = steady > 0.5 ? 3.0 : 9.0;
		color.rgb *= (0.82 + 0.3 * hash(floor(clock * rate + seed * 31.0))) * lights;
	} else if (kind == 6.0) {
		// Balizas: encendido corto y regular, desfasado por elemento.
		float on = step(fract(clock / 2.4 + hash(seed)), 0.32);
		color.rgb *= steady > 0.5 ? 0.9 : mix(0.38, 1.25, on);
	} else if (kind == 7.0) {
		// Ventilador: el disco se muestrea girado alrededor de su eje.
		vec4 fan = fans[int(seed + 0.5) % 2];
		vec2 local = texel + 0.5 - fan.xy;
		float angle = -clock * fan.w;
		vec2 turned = vec2(local.x * cos(angle) - local.y * sin(angle), local.x * sin(angle) + local.y * cos(angle));
		color = texture(TEXTURE, (floor(fan.xy + turned) + 0.5) / size);
	} else if (kind == 8.0) {
		// Estandarte: la onda baja por la tela y crece hacia el borde libre.
		float sway = sin(clock * 1.5 - param * 0.055 + hash(seed) * 6.0) * min(param / 38.0, 2.4);
		vec2 source = texel - vec2(floor(sway + 0.5), 0.0);
		bool body = seed > 127.0;
		if (kind_at(source, size) == 8.0 && texture(motion_mask, (source + 0.5) / size).g > 0.5) color = texture(TEXTURE, (source + 0.5) / size);
		else if (body) color = texture(TEXTURE, (source + 0.5) / size) * vec4(0.8, 0.8, 0.85, 1.0);
	} else if (kind == 9.0) {
		// Tira LED: un pulso recorre la tira de arriba abajo.
		float head = fract(clock * 0.55 + hash(seed));
		float near = 1.0 - step(0.18, abs(param / 255.0 - head));
		color.rgb *= steady > 0.5 ? 1.0 : mix(0.62, 1.35, near);
	} else if (kind == 10.0) {
		// Metal fundido: hervor en tres escalones y un temblor de calor de un téxel.
		float boil = sin(texel.x * 0.33 + clock * 1.4 + seed) * sin(texel.y * 0.47 - clock * 1.1);
		float level = floor(boil * 1.5 + 0.5) / 1.5;
		float wobble = steady > 0.5 ? 0.0 : floor(sin(texel.y * 0.7 + clock * 4.5) * 0.75 + 0.5);
		color = texture(TEXTURE, (texel + vec2(wobble, 0.0) + 0.5) / size);
		color.rgb *= 1.0 + level * 0.14;
		color.rgb = mix(color.rgb, vec3(1.0, 0.86, 0.5), max(level, 0.0) * 0.18);
	}
	COLOR = color * tint;
}

shader_type canvas_item;
uniform sampler2D screen_image : hint_screen_texture, repeat_disable, filter_nearest;
uniform float waterline = 0.75;
uniform vec4 water_tint : source_color = vec4(0.045, 0.10, 0.15, 1.0);
void fragment() {
	float depth = max(0.0, SCREEN_UV.y - waterline);
	vec2 uv = SCREEN_UV;
	uv.y = clamp(waterline * 2.0 - SCREEN_UV.y, 0.0, 1.0);
	float row = floor(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y / 2.0);
	uv.x += (sin(row * 0.43 + TIME * 1.4) + sin(row * 0.17 - TIME)) * SCREEN_PIXEL_SIZE.x * 1.1;
	vec3 reflection = texture(screen_image, uv).rgb;
	float strength = max(0.08, 0.48 - depth * 1.8);
	vec3 color = mix(water_tint.rgb, reflection * vec3(0.62, 0.78, 0.85), strength);
	color += vec3(0.08, 0.14, 0.17) * step(0.97, sin(row * 2.4 + TIME * 0.45)) * 0.25;
	COLOR = vec4(color, 1.0);
}

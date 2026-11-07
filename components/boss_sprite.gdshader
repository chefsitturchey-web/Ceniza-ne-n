shader_type canvas_item;
// Jefes finales: destello de impacto y tinte de fase sobre el pixel real (sin suavizado).
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform vec4 tint = vec4(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb *= tint.rgb;
	c.rgb = mix(c.rgb, flash_color.rgb, flash * step(0.5, c.a));
	COLOR = c * COLOR;
}

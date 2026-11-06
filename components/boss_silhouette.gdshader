shader_type canvas_item;
// Silueta plana del cuadro actual: el color sale de modulate. Se dibuja desplazada un texel
// en cuatro direcciones detrás del jefe para formar un contorno nítido de aviso.
void fragment() {
	COLOR = vec4(COLOR.rgb, step(0.5, texture(TEXTURE, UV).a) * COLOR.a);
}

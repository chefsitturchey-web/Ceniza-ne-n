# Prueba local de música 8 bit

La rama local `prueba/audio-8bit` combina nuestros avances de combate y sprites con `origin/audio/musica-8bit` (commit `41e9613`). Esta integración no publica cambios en `main` ni modifica la PR de los avances de combate.

## Probar en Godot

1. Abre el proyecto de esta carpeta y pulsa **F5**. El menú utiliza el nuevo tema.
2. Comprueba en **Opciones** que el control **Música** tenga volumen audible y que el sonido no esté silenciado.
3. Inicia una partida para escuchar el tema del distrito. El cambio de día a noche mezcla las pistas por fase y reproduce un aviso antes del asedio.
4. Pulsa **F1 → Jefes → Entrar** para probar un combate. Cada entrada elige uno de los nueve temas de jefe; puede repetirse porque la selección es aleatoria.

El conjunto incorpora 21 archivos OGG, incluyendo variantes de distrito, menú, noche, aviso, victoria y derrota. Victoria y derrota son cierres sin bucle; los temas de fondo se repiten.

Para volver a los avances sin esta música, con la partida detenida:

```powershell
git switch feature/clinica-audio-ambiente
```

Los borradores locales ajenos al audio se conservan fuera del commit de integración.

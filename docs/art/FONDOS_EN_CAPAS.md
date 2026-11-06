# Fondos vivos y marcos ornamentales

Los cinco distritos separan cielo y nubes, horizonte distante, arquitectura transparente y decoración cercana. La ciudad lejana, los edificios y las piezas cercanas avanzan al 10 %, 34 % y 62 % del desplazamiento de cámara. El suelo y las construcciones jugables conservan su posición física. La arquitectura mantiene sus siluetas y la paleta cambia suavemente con la hora y la zona.

| Distrito | Movimiento ambiental |
| --- | --- |
| Periferia | Vapor de chimeneas, ventiladores, tren y ventanas industriales |
| Fundición | Humo de hornos, colada enmascarada, metal hirviendo, brasas y ventanas |
| Barrio inundado | Lluvia, vapor de bombas, reflejos y oleaje que excluye los pilotes |
| Ciudadela | Cascadas con flujo, espuma y bruma al pie, agua, estandartes y velas |
| Red | Neones, ventanas, pulsos en tiras LED, vapor y drones |

La niebla separa los planos; las decoraciones cercanas quedan detrás de los edificios del jugador. Las arenas incorporan el arte de su distrito fuera del contorno transitable, conservando las señales y obstáculos del combate. La primera mantiene su composición propia de depósito y canales.

Las animaciones laterales se detienen al pausar. Las opciones de partículas y destellos reducidos atenúan efectos ambientales; el escenario y sus colisiones permanecen disponibles.

## Archivos editables y procedencia

- `assets/world/backgrounds/layers/`: cinco arquitecturas PNG transparentes, horizonte lejano y metadatos.
- `assets/world/backgrounds/sources/`: seis fuentes ASE editables en LibreSprite.
- `assets/world/backgrounds/references/`: pinturas originales y cuatro placas transparentes derivadas. Son entradas del proceso de arte; Godot no las importa.
- `assets/ui/frames/`: seis marcos originales, sus fuentes ASE, atlas de entrada y especificaciones.
- `components/district_depth.gd`: composición y velocidades; `components/backdrop_life.gd`: animación por distrito.

Se generaron un atlas ornamental y un horizonte originales con `image_gen`. Para Fundición, Inundado, Ciudadela y Red se editaron las pinturas existentes para obtener placas transparentes que conservan los edificios completos. LibreSprite registra las piezas, ajusta dimensiones y aperturas, y exporta ASE/PNG. La Periferia utiliza extracción del cielo de su pintura existente. Los prompts están junto a los recursos y los hashes de las doce fuentes ASE en `layers/provenance.json`.

```powershell
python tools/art/build_environment_art.py --libresprite "RUTA/libresprite.exe"
./tools/maintenance/validate.ps1 -GodotPath "RUTA/Godot_console.exe"
```

El generador detecta modificaciones manuales de los ASE y se detiene para conservarlas. `--overwrite-edits` permite reconstruirlos explícitamente. Sus archivos intermedios están en `build/art-depth/`, fuera de Git.

## Revisión

Con F5, camina por los distritos y compara las velocidades de los edificios al cambiar de dirección. Comprueba las animaciones y pausa. Desde F1 abre los cinco jefes para comparar sus marcos y los exteriores de las arenas. La guía de [interfaz de combate](../interface/INTERFAZ_COMBATE.md) describe las barras.

`environment_depth_test.gd` verifica 27 condiciones: tres velocidades, transparencia y fuentes de las cinco zonas, pausa, presentación sin desplazamiento físico y seis aperturas sin píxeles que tapen la vida. `-- --capture`, con renderizado gráfico, guarda capturas en `build/validation/latest/`. La batería completa contiene 61 suites; también se revisaron capturas OpenGL de los cinco distritos y cinco jefes.

Referencia técnica: [parallax 2D de Godot](https://docs.godotengine.org/en/4.5/tutorials/2d/2d_parallax.html). Referencia de lectura y ornamentación: [galería oficial de Elden Ring](https://it.bandainamcoent.eu/elden-ring/elden-ring/media). El arte producido es original del proyecto.

## Movimiento pintado por distrito

`components/animated_backdrop.gd` mantiene tres lienzos: cielo escalonado, arquitectura con shader y detalles. Comparten la camara y el espejo de cada tesela; los detalles usan las mismas coordenadas de origen que el PNG de 1024 x 576. No se crean nodos durante la animacion. El tiempo se cuantiza a 12 pasos por segundo y los detalles se redibujan a 20 Hz. Se conserva el humo existente.

`tools/art/build_backdrop_masks.py` muestrea los PNG mediante PIL y NumPy. Las mascaras lossless de `assets/world/backgrounds/masks/` guardan tipo, semilla y distancia en RGB. El shader usa nearest, centros de texel, desplazamientos enteros y trama ordenada. Las cascadas de Ciudadela estan en x=295..323 y 350..377, y la inferior en x=281..327; la colada de Fundicion, x=172..192. Los ventiladores de Periferia giran dentro de sus discos originales, centrados en (191,319) y (852,333). El tren cruza la via y=244 durante 13 de cada 38 segundos. Las luces varian con la hora; aves diurnas y drones nocturnos cruzan todos los distritos.

Con particulas desactivadas, el shader devuelve el arte original y los detalles dejan de dibujarse. `WorldParticles.budget` limita lluvia, ceniza, espuma, bruma y siluetas. Destellos reducidos elimina el zumbido y los cortes de neon, estabiliza las balizas y reduce los efectos. Pausar detiene el tiempo del fondo.

Para regenerar las mascaras y sus vistas de inspeccion:

```powershell
python tools/art/build_backdrop_masks.py --preview build/capturas/fondos
```

`tests/backdrop_motion_test.gd` comprueba las cinco mascaras, varios tipos de movimiento en cada distrito, tiempo, particulas desactivadas y destellos reducidos. Se incluye en `run_all`. Las capturas de revision estan en `build/capturas/fondos/`: cinco cuadros separados por 0.15 s para cada distrito y cada hora, GIFs y hojas `*_contacto.png`. El script temporal `capture.gd` carga `levels/main.tscn`, mueve al jugador con `Input.action_press` y captura el viewport con renderizado en ventana.

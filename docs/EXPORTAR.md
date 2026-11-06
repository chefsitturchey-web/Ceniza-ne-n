# Exportar Ceniza Neón

Configuración comprobada en `project.godot` y `export_presets.cfg`: versión `0.2.0-alpha`, base de 640 × 360, ventana de 1280 × 720, `canvas_items`, `keep_height` y renderizador Compatibility. El motor indicado para este proyecto es Godot 4.7.2.

| Preset | Salida configurada | Configuración |
| --- | --- | --- |
| Windows Desktop | `build/windows/CenizaNeon.exe` | x86_64, PCK separado |
| Web | `build/web/index.html` | Sin hilos (`variant/thread_support=false`) |
| Android | `build/android/CenizaNeon.apk` | arm64-v8a, sin compilación Gradle, paquete `com.cenizaneon.juego` |

Los tres presets excluyen `tests/*` y `tools/*`. Las carpetas con `.gdignore` no se importan. Los iconos configurados son `assets/ui/app_icon.png` y `assets/ui/app_icon.ico`.

## Preparar y exportar

Instala las plantillas de exportación que correspondan al motor. Para Android configura también JDK, SDK y firma en el editor. Sus ubicaciones y el estado de las instalaciones son propios de cada equipo; no forman parte del código versionado.

Desde la raíz, valida primero:

```powershell
$godotCeniza = "D:\descargas\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
powershell -File tools\maintenance\validate.ps1 -GodotPath $godotCeniza
New-Item -ItemType Directory -Force build/windows, build/web, build/android
& $godotCeniza --headless --path . --export-release "Windows Desktop" build/windows/CenizaNeon.exe
& $godotCeniza --headless --path . --export-release "Web" build/web/index.html
& $godotCeniza --headless --path . --export-debug "Android" build/android/CenizaNeon.apk
```

Estos comandos son instrucciones de reproducción, no resultados de exportaciones ejecutadas en esta revisión. El tamaño final y el arranque deben comprobarse en cada compilación.

## Comprobar la entrega

- Windows: distribuir el ejecutable y su PCK juntos; abrir y probar menú, campaña y Boss Rush.
- Web: servir `build/web/` con `python -m http.server 8000` desde esa carpeta y abrir `http://localhost:8000`. Probar carga, entrada y audio en el navegador objetivo.
- Android: instalar el APK de prueba y comprobar orientación, área segura, botones, pausa y sonido en el dispositivo.

`ui/touch_controls.gd` ofrece joystick y acciones de colonia/arena; Opciones permite ocultarlos. `core/screen_fit.gd` centra paneles y aplica márgenes seguros. `audio/driver/output_latency.android=10` es un ajuste configurado, no una medición de latencia final. `UiSound.warm_up()` carga los efectos de interfaz al arrancar.

Para actualizar la versión, revisar `config/version` y los campos `version/name` y `version/code` del preset Android. La firma de distribución se configura fuera de Git. Esta guía no ejecuta ni presupone una publicación.

[Herramientas y validación](../tools/README.md) · [Audio](audio/AUDIO.md).

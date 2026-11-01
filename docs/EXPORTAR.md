# Exportar Ceniza Neón (Windows, Web, Android)

Versión actual: **0.1.0-alpha** (`application/config/version` en `project.godot`).
Icono: `assets/ui/app_icon.png` (256 px) y `assets/ui/app_icon.ico` para Windows. Es un recorte del retrato neón de `assets/characters/portraits/portraits_manga_v2.png`.

Los presets están en `export_presets.cfg`. Todo lo exportado va a `build/`, que está en `.gitignore`.

| Preset | Salida | Notas |
|---|---|---|
| `Windows Desktop` | `build/windows/CenizaNeon.exe` + `CenizaNeon.pck` | x86_64, el `.pck` va aparte (no embebido) |
| `Web` | `build/web/index.html` (+ `.js`, `.wasm`, `.pck`, worklets, iconos) | **Sin hilos**: funciona en cualquier hosting estático, sin cabeceras COOP/COEP |
| `Android` | `build/android/CenizaNeon.apk` | Solo arm64-v8a, horizontal (landscape), pantalla inmersiva, paquete `com.cenizaneon.juego` |

Los tres excluyen `tests/*` y `tools/*`. Las carpetas `sources/` (archivos .ase) ya tienen `.gdignore`, así que no entran al paquete.

## Requisitos comunes

- Godot 4.7.2: `D:\descargas\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
- Plantillas de exportación 4.7.2: están en `D:\DevTools\godot-templates\4.7.2.stable` (2,0 GB).
  `%APPDATA%\Godot\export_templates\4.7.2.stable` es una **unión de directorio** (`mklink /J`) que apunta ahí, así que no ocupan espacio en C:.
  Si alguna vez se borra la unión:
  ```cmd
  mklink /J "%APPDATA%\Godot\export_templates\4.7.2.stable" "D:\DevTools\godot-templates\4.7.2.stable"
  ```
  Origen: `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz` (1,2 GB comprimido; es un zip con la carpeta `templates/`).

En los comandos siguientes:
```bash
G="/d/descargas/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
cd "/d/descargas/Proyectos personales/Ceniza-export"   # o la carpeta del proyecto
mkdir -p build/windows build/web build/android
```
Si el proyecto es un clon nuevo (sin `.godot/`), primero hay que importar: `"$G" --headless --path . --import`.

## Windows

```bash
"$G" --headless --path . --export-release "Windows Desktop" build/windows/CenizaNeon.exe
```
Resultado (1/11/2026): `CenizaNeon.exe` 109 MB + `CenizaNeon.pck` 98 MB. Para repartirlo hay que comprimir **los dos archivos juntos** en un zip.
El icono del .exe lo pone Godot automáticamente (no hace falta rcedit).

## Web (HTML5)

```bash
"$G" --headless --path . --export-release "Web" build/web/index.html
```
Resultado: `index.wasm` 39,5 MB + `index.pck` 98 MB + archivos pequeños (unos 137 MB en total).

Prueba local (no sirve abrir `index.html` con doble clic; necesita un servidor):
```bash
cd build/web
python -m http.server 8000
# abrir http://localhost:8000
```
Comprobado: `index.html`, `index.js`, `index.wasm` (application/wasm) e `index.pck` responden HTTP 200.

Como la variante es **sin hilos** (`variant/thread_support=false`), no se necesitan las cabeceras `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy`. El precio es que el audio puede ir un poco peor en equipos lentos; para este juego no debería notarse.

Ojo con el tamaño: el `.pck` pesa 98 MB (sobre todo `assets/characters`, `assets/world` y `assets/audio`). Tarda en cargar con conexiones lentas. Más adelante conviene comprimir el audio (OGG en vez de WAV) o recortar arte que no se use.

### Opciones de hosting (no se ha publicado nada)

**itch.io** (lo más simple para un juego):

Preparar el zip (el `index.html` tiene que quedar en la **raíz** del zip, no dentro de una carpeta):
```powershell
Compress-Archive -Path build\web\* -DestinationPath build\CenizaNeon-web-0.1.0-alpha.zip -Force
```
Resultado (1/11/2026): `build/CenizaNeon-web-0.1.0-alpha.zip` de **107 MB** (106 657 730 bytes), 9 archivos. El más grande es `index.pck` (97,8 MB); después `index.wasm` (39,5 MB). Límites de itch: máximo 200 MB por archivo dentro del zip y máximo 1000 archivos, así que entra.

Subida por la web (no se ha subido nada todavía):
1. itch.io → *Upload new project*.
2. *Kind of project*: **HTML**.
3. *Uploads* → subir `CenizaNeon-web-0.1.0-alpha.zip` → marcar **This file will be played in the browser**.
4. *Embed options*:
   - *Viewport dimensions*: **1280 × 720** (el proyecto es 640×360 con `canvas_items` y ventana de 1280×720, así que escala exacto ×2).
   - **Mobile friendly**: ya hay controles táctiles (ver «Móvil» en la sección Android).
   - Activar **Fullscreen button**.
   - **No** activar *SharedArrayBuffer support*: la versión web es sin hilos (`variant/thread_support=false`) y no lo necesita.
5. *Visibility*: dejarlo en **Draft** o **Restricted** (con contraseña) para probar en privado antes de publicarlo.

Alternativa con **butler** (la herramienta de línea de comandos de itch; sube solo lo que cambió, útil para actualizaciones):
```powershell
# Instalar butler en D: (no en C:): descargar https://broth.itch.ovh/butler/windows-amd64/LATEST/archive/default
# y descomprimir en D:\DevTools\butler
D:\DevTools\butler\butler.exe login
D:\DevTools\butler\butler.exe push build\web USUARIO/ceniza-neon:html5 --userversion 0.1.0-alpha
```
- Se puede empujar la carpeta `build/web` directamente (no hace falta el zip).
- El canal se llama `html5` (cualquier nombre con "html" sirve). Después de la primera subida hay que entrar en la página del proyecto y marcar ese archivo como *This file will be played in the browser* (solo la primera vez).
- `butler login` guarda la clave en `%USERPROFILE%\.config\itch`. Para dejarla en D: se puede usar `--identity D:\DevTools\butler\butler_creds` en `login` y en `push`.

**Cloudflare** (ya lo usas para Casa H&L):
- Límite importante: **25 MiB por archivo** en Pages y en los assets estáticos de Workers. `index.wasm` (39,5 MB) y `index.pck` (98 MB) **lo superan**, así que no se pueden subir directamente.
- Opciones:
  1. **Workers + R2**: subir `index.wasm` e `index.pck` a un bucket R2 y servirlos desde ahí (R2 no tiene límite de 25 MiB). El resto (`index.html`, `.js`, iconos) va como assets estáticos del Worker. El Worker o una regla redirige `/index.pck` y `/index.wasm` al bucket, o se publica el bucket con dominio propio y se cambia la ruta en el HTML.
  2. Reducir el `.pck` por debajo de 25 MiB (difícil sin recortar mucho) y comprimir el `.wasm` (Cloudflare ya lo sirve comprimido, pero el límite cuenta el archivo sin comprimir).
- Ejemplo con Workers static assets cuando los archivos quepan (`wrangler.jsonc`):
  ```jsonc
  {
    "name": "ceniza-neon",
    "compatibility_date": "2026-10-01",
    "assets": { "directory": "./build/web" }
  }
  ```
  y `npx wrangler deploy` (**no ejecutado**).
- Resumen: para la primera alfa, **itch.io es lo más directo**. Cloudflare queda para cuando se quiera dominio propio (con R2 para los archivos grandes).

## Android

### Herramientas instaladas (todo en D:, 1/11/2026)

| Herramienta | Ruta | Tamaño |
|---|---|---|
| JDK 17 (Eclipse Temurin 17.0.20.1+1, zip x64) | `D:\DevTools\jdk-17` | 303 MB |
| Android SDK mínimo | `D:\DevTools\android-sdk` | 410 MB |
| ↳ cmdline-tools 19.0 | `D:\DevTools\android-sdk\cmdline-tools\latest` | |
| ↳ platform-tools 37.0.1 (`adb`) | `D:\DevTools\android-sdk\platform-tools` | |
| ↳ build-tools 35.0.1 (`apksigner`, `zipalign`) | `D:\DevTools\android-sdk\build-tools\35.0.1` | |
| ↳ platforms android-35 | `D:\DevTools\android-sdk\platforms\android-35` | |
| Keystore de depuración | `D:\DevTools\android-keystore\debug.keystore` (alias `androiddebugkey`, contraseña `android`) | 3 KB |
| Caché de las herramientas Android | `D:\DevTools\android-user-home` (`ANDROID_USER_HOME`) | 3 MB |
| Caché de Gradle (vacía, sin uso aún) | `D:\DevTools\gradle-user-home` (`GRADLE_USER_HOME`) | 0 |

El NDK y CMake **no** están instalados: no hacen falta porque el preset no usa la compilación Gradle (`gradle_build/use_gradle_build=false`). Solo harían falta para un AAB (ver *Release*).

El SDK viejo de **C:** (`%LOCALAPPDATA%\Android\Sdk`, 4,3 GB) sigue ahí sin tocar; Godot ya no lo usa.

Cómo se instaló (por si hay que repetirlo o añadir paquetes):
```cmd
REM JDK: https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse  -> descomprimir en D:\DevTools\jdk-17
REM cmdline-tools: https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip -> D:\DevTools\android-sdk\cmdline-tools\latest
set JAVA_HOME=D:\DevTools\jdk-17
set ANDROID_USER_HOME=D:\DevTools\android-user-home
set GRADLE_USER_HOME=D:\DevTools\gradle-user-home
set SM=D:\DevTools\android-sdk\cmdline-tools\latest\bin\sdkmanager.bat
%SM% --sdk_root=D:\DevTools\android-sdk --licenses
%SM% --sdk_root=D:\DevTools\android-sdk "platform-tools" "build-tools;35.0.1" "platforms;android-35"
```
Conviene definir `ANDROID_USER_HOME` y `GRADLE_USER_HOME` siempre que se use `sdkmanager`, `adb` o Gradle, para que no escriban en `C:\Users\...`.

### Configuración del editor de Godot

En `%APPDATA%\Godot\editor_settings-4.7.tres` (Editor → Configuración del editor → Exportar → Android):
- `export/android/java_sdk_path` = `D:/DevTools/jdk-17`
- `export/android/android_sdk_path` = `D:/DevTools/android-sdk`
- `export/android/debug_keystore` = `D:/DevTools/android-keystore/debug.keystore` (usuario `androiddebugkey`, que es el valor por defecto, y contraseña `android`)

La keystore de depuración se creó a mano con:
```cmd
D:\DevTools\jdk-17\bin\keytool -genkeypair -v -keystore D:\DevTools\android-keystore\debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
```

### APK de prueba (debug)

```bash
"$G" --headless --path . --export-debug "Android" build/android/CenizaNeon.apk
```
Resultado (1/11/2026, con controles táctiles): `build/android/CenizaNeon.apk` de **126 MB** (126 426 018 bytes), solo arm64-v8a, firmado con la keystore de depuración (`apksigner verify` sin errores). No hizo falta tocar el preset.

Instalar en el móvil (con la depuración USB activada):
```cmd
D:\DevTools\android-sdk\platform-tools\adb install -r build\android\CenizaNeon.apk
```
### Release

Para repartirlo o subirlo a una tienda hace falta una keystore propia (todavía no existe). Guardarla **fuera del repo** y **nunca** subirla a git:
```cmd
D:\DevTools\jdk-17\bin\keytool -genkeypair -v -keystore D:\DevTools\keys\ceniza-release.keystore -alias ceniza -keyalg RSA -keysize 2048 -validity 10000
```
No guardes la contraseña en `export_presets.cfg` (que está en git). Pásala por variables de entorno al exportar:
`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`, y luego `--export-release "Android" ...`.

Para Google Play hace falta un AAB (`gradle_build/use_gradle_build=true` + `export_format=1`). Eso exige instalar la plantilla Gradle, el NDK `ndk;28.1.13356709` y `cmake;3.10.2.4988404` (+2–3 GB, también en `D:\DevTools\android-sdk`). Para alfa por APK no hace falta.

### Móvil: controles táctiles, pantalla ancha y audio

**Controles táctiles** (`ui/touch_controls.gd`, autoload `TouchControls`, clase `TouchOverlay`):
- Aparecen solo si hay pantalla táctil (`DisplayServer.is_touchscreen_available()` u `OS.has_feature("mobile")`), durante el juego y sin pausa. En escritorio sin pantalla táctil no se ven. Opciones → «Controles táctiles en pantalla» los oculta (preferencia `touch_controls` en `user://opciones.cfg`).
- Izquierda: joystick flotante (nace donde apoyas el pulgar, en el 45 % izquierdo de la pantalla). En las zonas solo mueve izquierda/derecha; en las arenas de jefe también arriba/abajo (`arena_up`/`arena_down`, analógico).
- Derecha, en zonas: Operar (mantener E), Esquivar, Correr (mantener), Asaltar (F), Sobrecargar (Q), Torreta (T), Plataforma (V). En arenas: Atacar (J), Esquivar, Correr, Operar, Sobrecargar.
- Arriba a la derecha: Pausa y Diario (Diario solo en zonas; con el panel táctil se oculta el botón «L · Diario» del HUD para no repetirlo).
- Inyectan `InputEventAction` con `Input.parse_input_event`, así que funcionan igual que el teclado tanto para `Input.is_action_*` como para `_input`/`_unhandled_input`. Multitáctil; al pausar, perder el foco o cambiar de modo se sueltan todas las acciones.
- Menús y paneles: los toques llegan a los botones como ratón emulado (`input_devices/pointing/emulate_mouse_from_touch=true`); lo comprueba `tests/touch_controls_test.gd`.

**Pantalla ancha** (antes quedaban franjas negras en un 20:9):
- `window/stretch/aspect="keep_height"`: el alto lógico sigue siendo 360 y el ancho crece (≈800 en 20:9). En 16:9 (escritorio 1280×720) todo queda igual que antes.
- `core/screen_fit.gd`: los paneles de diseño fijo (opciones, diario, clínica, tienda, informe, elección de nivel, novela) y la arena de jefe se centran y su fondo cubre todo el ancho. El HUD se reparte por el ancho visible y el menú principal estira la ilustración sin deformarla.
- Notch: el preset Android tiene `screen/edge_to_edge=true` y `ScreenFit.safe_margins()` (usa `DisplayServer.get_display_safe_area()`, solo en móvil) aparta del recorte el HUD, el menú y los controles táctiles.

**Retraso del sonido**:
- `audio/driver/output_latency.android=10` (por defecto 15 ms). Ojo: Android usa el driver OpenSL ES de Godot, que puede ignorar este ajuste y fijar su propio búfer; además el sistema y el hardware añaden su propia latencia (en muchos móviles 50–150 ms), que el juego no puede quitar. Si se oyen chasquidos, subirlo a 15–20.
- `UiSound`: los WAV de interfaz se cargan al arrancar (antes se leían del disco en el primer toque) y el clic suena al apretar (`button_down`), no al levantar el dedo. En pantallas táctiles no suenan además el «roce» y el «láser» de foco encima del clic.
- Los efectos de juego (`GameSound.CUES`) ya estaban precargados y sin llamadas diferidas; los WAV no tienen silencio inicial (medido: < 10 ms salvo dos ambientes en bucle).

## Comprobaciones rápidas después de exportar

- `build/windows/CenizaNeon.exe` y `CenizaNeon.pck` existen y el exe arranca hasta el menú.
- `build/web/` servido con `python -m http.server`: `index.html`, `index.wasm` e `index.pck` responden 200 y el juego llega al menú.
- Cambiar la versión: subir `config/version` en `project.godot`; en Android, además, `version/code` (+1) y `version/name` en el preset.

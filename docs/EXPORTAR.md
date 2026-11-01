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
1. Comprimir el **contenido** de `build/web/` en un zip (el `index.html` tiene que quedar en la raíz del zip, no dentro de una carpeta).
2. En itch.io: crear proyecto → *Kind of project: HTML* → subir el zip → marcar *This file will be played in the browser*.
3. Tamaño de ventana: 1280×720, activar *Fullscreen button*. **No** hace falta activar *SharedArrayBuffer support* (porque la versión es sin hilos).
4. Límites de itch: un archivo como máximo de 200 MB dentro del zip y como máximo 1000 archivos. Ahora entramos (el más grande es el `.pck`, de 98 MB).
5. Se puede dejar como *Draft* o *Restricted* (con contraseña) para probar en privado.

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

### Qué falta (bloqueante)

Al exportar sale este error:
```
Se requiere una ruta válida para el SDK de Java en la Configuración del Editor.
```

Estado de las dependencias (revisado el 1/11/2026):

| Dependencia | Estado |
|---|---|
| JDK 17 | **No hay.** En D: solo está `D:\DevTools\jdk-25.0.4.1+1`. Godot pide oficialmente JDK 17 para las herramientas de Android. |
| Android SDK en D: | **No hay.** Hay uno de 4,3 GB en **C:** (`%LOCALAPPDATA%\Android\Sdk`, con build-tools 34–36, platform-tools, cmdline-tools y NDK 28). La configuración del editor de Godot ya apunta ahí. |
| Plantillas Android | Ya están (dentro de las plantillas 4.7.2, en D:). |
| Keystore de depuración | Godot la crea sola al exportar en debug. |
| Keystore de release | No hay. Hace falta para `--export-release` y para publicar. |

### Pasos para dejarlo funcionando (todo en D:)

1. **JDK 17** (Eclipse Temurin, zip para Windows x64): ~190 MB de descarga y ~320 MB descomprimido.
   - Descargar desde `https://adoptium.net/temurin/releases/?version=17` (o con la API: `https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse`).
   - Descomprimir en `D:\DevTools\jdk-17` (sin instalador, sin tocar C:).
2. **Android SDK**. Elegir una opción:
   - **A (sin descargar nada):** usar el SDK que ya está en C:. Funciona, pero rompe la regla de "todo en D:".
   - **B (recomendada):** moverlo a D:. Cerrar Android Studio, Flutter y Gradle; mover `%LOCALAPPDATA%\Android\Sdk` a `D:\DevTools\Android\Sdk` (4,3 GB) y, si otras herramientas lo usan, dejar una unión: `mklink /J "%LOCALAPPDATA%\Android\Sdk" "D:\DevTools\Android\Sdk"`.
   - **C (mínimo y limpio en D:):** instalar solo lo que necesita Godot, unos **0,6–1 GB**:
     ```cmd
     REM cmdline-tools (~150 MB) descomprimidos en D:\DevTools\Android\Sdk\cmdline-tools\latest
     set JAVA_HOME=D:\DevTools\jdk-17
     D:\DevTools\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=D:\DevTools\Android\Sdk "platform-tools" "build-tools;35.0.1" "platforms;android-35"
     ```
     El NDK y CMake **no** hacen falta, porque el preset no usa la compilación Gradle (`gradle_build/use_gradle_build=false`).
3. **Configurar Godot**: Editor → Configuración del editor → Exportar → Android:
   - `java_sdk_path` = `D:/DevTools/jdk-17`
   - `android_sdk_path` = `D:/DevTools/Android/Sdk` (o la ruta de C: si se eligió la opción A)
   - `debug_keystore`: por defecto queda en `%APPDATA%\Godot\keystores\debug.keystore` (C:, pesa 2 KB). Se puede mover a D: y cambiar la ruta aquí.
4. **Exportar APK de prueba** (firmado con la keystore de depuración):
   ```bash
   "$G" --headless --path . --export-debug "Android" build/android/CenizaNeon.apk
   ```
   Instalar en el móvil: `adb install -r build/android/CenizaNeon.apk` (con la depuración USB activada).
5. **Release** (para repartirlo o subirlo a una tienda): crear una keystore propia, guardarla **fuera del repo** y **nunca** subirla a git:
   ```cmd
   D:\DevTools\jdk-17\bin\keytool -genkeypair -v -keystore D:\DevTools\keys\ceniza-release.keystore -alias ceniza -keyalg RSA -keysize 2048 -validity 10000
   ```
   No guardes la contraseña en `export_presets.cfg` (que está en git). Pásala por variables de entorno al exportar:
   `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`, y luego `--export-release "Android" ...`.
   Para Google Play hace falta un AAB (`gradle_build/use_gradle_build=true` + `export_format=1`). Eso exige instalar la plantilla Gradle, el NDK y CMake (+2–3 GB). Para alfa por APK no hace falta.

Total aproximado para la opción C: **~1–1,3 GB en D:** (JDK 17 + SDK mínimo).

### Controles táctiles: PENDIENTE

El juego **no tiene controles táctiles**: no hay `TouchScreenButton`, `VirtualJoystick` ni manejo de `InputEventScreenTouch` en el código del juego. En Android se podrá abrir, pero sin teclado ni mando no se podrá jugar bien. Antes de repartir el APK hay que implementar los controles táctiles (por ejemplo con el `VirtualJoystick` de Godot 4.7 y botones en pantalla). Para usarlo en móvil desde la versión web también hacen falta.

## Comprobaciones rápidas después de exportar

- `build/windows/CenizaNeon.exe` y `CenizaNeon.pck` existen y el exe arranca hasta el menú.
- `build/web/` servido con `python -m http.server`: `index.html`, `index.wasm` e `index.pck` responden 200 y el juego llega al menú.
- Cambiar la versión: subir `config/version` en `project.godot`; en Android, además, `version/code` (+1) y `version/name` en el preset.

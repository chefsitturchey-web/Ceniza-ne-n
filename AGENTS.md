# Trabajo en CENIZA NEÓN

- El usuario está aprendiendo Godot. Explicar brevemente cada entrega y cómo probarla, en español.
- Conservar los ajustes y cambios realizados por el usuario.
- Registrar avances coherentes y comprobados mediante un commit local solo cuando la instrucción vigente del usuario lo autorice. Si pide no hacer commit ni push, conservar los cambios sin confirmar. Revisar los archivos incluidos antes de cualquier commit y comunicar el resultado.
- No incluir cachés de Godot, exportaciones ni logs de validación en los commits.
- Ejecutar las validaciones con `tools/maintenance/validate.ps1`; los registros van en `build/validation/latest/` y el resumen en `summary.json`. `tests/run_all.gd` registra 67 ejecuciones de suites, incluidas variantes con argumentos. No crear `validation*.log` en la raíz. Herramientas de arte en `tools/art/`, audio en `tools/audio/` e integraciones en `tools/integrations/`.
- Guardar sprites de personajes en `assets/characters/`, escenarios en `assets/world/` y guías por tema en `docs/`, manteniendo su índice. Contrastar las afirmaciones de los `.md` con código y recursos actuales; distinguir implementación de especificaciones y no prometer trabajos supuestos. No reintroducir los paquetes retirados de `assets/player`, `assets/unidades` o combate geométrico como recursos ocultos de respaldo.
- Publicar en un remoto solo cuando el usuario lo solicite.
- Preferencia del usuario: avanzar por bloques jugables grandes, reducir explicaciones y llamadas innecesarias. Si hacen falta recursos externos, entregar prompts y especificaciones visuales consistentes.

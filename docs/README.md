# Documentación de CENIZA NEÓN

- [Inicio para jugar](../INICIO.md).
- [Organización, limpieza y archivos generados](ORGANIZACION.md).
- [Dónde están los sprites y sonidos](../assets/README.md).
- [Flujo completo de historia y novela visual](gameplay/HISTORIA_FLUJO.md).
- [Boss Rush, ranking local y online](gameplay/BOSS_RUSH.md).
- [Exportar para Windows, Web y Android](EXPORTAR.md).
- [Cómo colaborar: ramas, pruebas y versiones](../CONTRIBUIR.md).

## Diseño y campaña

[Documento de diseño](design/CENIZA_NEON_GDD.docx) · [Historia y campaña actual](design/HISTORIA_Y_CAMPANA.md) · [Reglas inspiradas en Kingdom y Vampire Survivors](design/REVISION_GDD_KINGDOM_SURVIVORS.md)

## Mecánicas

- [Trabajo nocturno con riesgo](gameplay/TRABAJO_NOCTURNO.md).
- [Primeros pasos, impacto, combos y resultados](gameplay/PRIMEROS_PASOS_Y_RONDAS.md).
- [Poblados en ruinas, componentes especiales e instalaciones de apoyo](gameplay/POBLADOS_Y_TECNOLOGIA.md).
- [Reglas actuales: cinco fronteras, núcleo desde cero, despejes y mochila](gameplay/FRONTERA_Y_RECONSTRUCCION.md).
- [Invasión: piezas, taller, plagas y compatibilidad con jefes](gameplay/INTEGRACION_INVASION.md).
- [Construcción, niveles y movilidad](gameplay/ESCALA_NIVELES_Y_MOVILIDAD.md).
- [Comandante, unidades y portales](gameplay/COMANDANTE_Y_PORTALES.md).
- [Trabajadores, profesiones y depósito](gameplay/DEPOSITO_Y_VIDA_DEL_DISTRITO.md).
- [Armas, pasivas y evoluciones](gameplay/MODULOS_Y_EVOLUCIONES.md).
- [Tácticas y arenas](gameplay/JEFES_TACTICAS_Y_ARENAS.md).
- [Marcha, impactos y presión de los jefes](gameplay/EFECTOS_Y_PRESION_JEFES.md).

## Arte

- [Humo, bruma, portales y presupuestos de efectos](art/AMBIENTE_Y_PORTALES.md).
- [Fondos vivos, capas y marcos ornamentales](art/FONDOS_EN_CAPAS.md).
- [Portador y jefes: diseño y proceso vigente](art/ARTE_COMBATE_ILUSTRADO.md).
- [Aliados y animaciones de enemigos](art/PERSONAJES_Y_ANIMACIONES.md).
- [Novela visual y retratos](art/NOVELA_VISUAL_Y_COHERENCIA.md).
- [Siluetas mecánicas del asedio](art/SILUETAS_MECANICAS.md).
- [Referencias visuales](art/REFERENCIAS_VISUALES.md), [procedencia y licencias](art/ASSET_SOURCES.csv), [trabajos de estructuras](art/FORTRESS_ASSET_JOBS.json).
- [Guía de arte del usuario](GUIA_ARTE.md).

## Interfaz, sonido y desarrollo

Las funciones de interfaz, coberturas y diálogos se describen en [arsenal y acabado de menús](interface/MENU_Y_OPCIONES.md), [coberturas y cierre del Coro](gameplay/EFECTOS_Y_PRESION_JEFES.md) y [diálogos y retratos de los cinco jefes](art/NOVELA_VISUAL_Y_COHERENCIA.md).

[Vida y marcos de combate](interface/INTERFAZ_COMBATE.md) · [Menús y opciones](interface/MENU_Y_OPCIONES.md) · [Laboratorio F1](interface/LABORATORIO_DEPURACION.md) · [Audio](audio/AUDIO.md) · [Arquitectura actual](development/ARQUITECTURA.md) · [Herramientas](../tools/README.md)

Las guías contrastan el estado con los scripts citados. `tests/run_all.gd` registra 67 ejecuciones; usar `tools/maintenance/validate.ps1` y consultar `build/validation/latest/summary.json`. Las especificaciones de arte son pautas para solicitudes nuevas, no trabajos futuros confirmados.

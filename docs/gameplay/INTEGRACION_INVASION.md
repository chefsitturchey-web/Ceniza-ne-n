# Invasión: recuperación, plagas y bajas

Esta guía describe los sistemas activos; las referencias de merges y respaldos antiguos no son requisitos para jugar. [Frontera](FRONTERA_Y_RECONSTRUCCION.md) detalla mapa, núcleo, mochila y depósito.

- `ScavengeSystem` y `ScavengeProp`: extracción con E de piezas y chatarra; cargas y posiciones persistentes.
- `WorkshopSystem`: fabricación de pala y trampas. El Arsenal reúne las compras; las herramientas de profesión siguen sus requisitos de plaza.
- `CorpseSystem` y `Corpse`: bajas, descomposición, contaminación y cadáveres reportados para entierro con pala y constructor.
- `PestSystem`, `SewerRat` y `TrapSystem`: plagas, averías de torretas y captura con trampas.
- `InvasionState` y `SaveSystem`: serialización y validación de objetos, piezas, herramientas, trampas, cadáveres y trabajadores.

Los trabajadores tienen 60 de salud. Pueden morir; una orden nocturna los expone como objetivos y les permite trabajar bajo amenaza hasta el amanecer. Los soldados derrotados pierden la profesión y vuelven a civiles según `CivicSystem`; no se duplican como trabajador muerto. [Trabajo nocturno](TRABAJO_NOCTURNO.md).

El tren comprueba que permanezcan constructor y recuperador para el relevo. El traspaso conserva las piezas de mochila según las reglas de campaña; el depósito y la tecnología de poblados pertenecen al distrito. El combate de arena usa su propio controlador y no hereda el ritmo de marcha de la colonia.

## Arte activo

Rata, batería, antena, trampa y piezas cuentan con sprites y fuentes en `assets/characters/pests/` y `assets/world/salvage/`. No deben describirse como figuras geométricas pendientes de sustituir. Los editables y las herramientas de reconstrucción se conservan.

## Probar

F5 → Nueva partida: extraer piezas, fabricar herramientas y comprobar trampas o un entierro. F1 permite preparar amenazas en práctica sin sobrescribir el checkpoint. Ejecutar `tools/maintenance/validate.ps1`; `invasion_integration_test` y `night_work_test` forman parte de las 67 ejecuciones de `tests/run_all.gd`. Los registros quedan en `build/validation/latest/`.

# Trabajo nocturno con riesgo

`systems/colony_system.gd` permite trabajar de día y, de noche, cuando el jugador acepta una orden que llama a `authorize_night_work()`. Construir, reparar, mejorar, despejar, restaurar una instalación o encargar el núcleo pueden habilitarlo. Una orden rechazada no autoriza la salida.

El aviso **«De noche: tu gente puede morir»** aparece una vez esa noche. La autorización dura hasta el amanecer; los trabajadores continúan aunque haya enemigos cerca y usan el **80 % del ritmo** normal (`GameRules.NIGHT_WORK_PACE`). No se retiran automáticamente por proximidad mientras ese permiso está activo.

`entities/colony/worker.gd` incorpora a los trabajadores vivos expuestos al grupo `night_workers`, que los enemigos pueden atacar. Comparten su salud de 60 con el daño de peligro por proximidad. Las bajas y los cadáveres pertenecen a los sistemas existentes de invasión; no hay una protección nocturna implícita.

## Probar

Con una colonia construida y recursos, espera a la noche y encarga una obra con E. Comprueba el aviso, el desplazamiento y el trabajo. Observa el riesgo cerca de enemigos; al amanecer se restablece el comportamiento diurno. El laboratorio F1 permite preparar el escenario en una sesión de práctica.

`tests/night_work_test.gd` comprueba los tipos de orden, rechazo sin recursos, aviso único, progreso bajo amenaza, objetivos enemigos y retorno al amanecer. Ejecutar mediante `tools/maintenance/validate.ps1`; está en las 67 ejecuciones de `tests/run_all.gd`.

[Invasión y bajas](INTEGRACION_INVASION.md) · [Construcción](FRONTERA_Y_RECONSTRUCCION.md).

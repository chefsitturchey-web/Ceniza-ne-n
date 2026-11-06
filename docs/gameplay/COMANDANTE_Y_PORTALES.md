# Comandante, escuadras y portales

En la colonia el Portador organiza, recluta, construye, esquiva y activa la sobrecarga. J y las armas automáticas personales no dañan enemigos ni entradas. En las arenas se conserva el combate manual y automático. Los módulos equipados transmiten una bonificación de daño a los soldados; las mejoras siguen teniendo utilidad antes del jefe.

F ordena atacar el frente donde está el Portador; otra pulsación retira la escuadra. Hace falta un cuartel construido, personas reclutadas en los campamentos y herramientas compradas en el taller: fusiles para tiradores y escudos para guardianes. Conviene llevar ambos. Las tropas se defienden durante el avance aunque estén lejos de su cuartel.

Cada portal responde al primer impacto y al cruzar 200 y 100 puntos de vida. El aviso dura 0,8 segundos; después salen dos defensores de su boca. Estos enemigos no dan chatarra, experiencia ni cofres. La reserva depende de los umbrales de salud, no se repone al retirarse. Un portal destruido cancela la respuesta pendiente. Las brechas intermedias mantienen además el contraataque tras su destrucción cuando quedan entradas en ese frente.

El generador inicial se sitúa a 360 unidades del núcleo: no exige atravesar la puerta que necesitas energía para asaltar. Las colonias avanzadas empiezan con la primera composición nocturna y aumentan hasta la tercera, dando tiempo para reclutar.

## Referencias de diseño

- [Descripción oficial de Kingdom Two Crowns](https://kingdomthegame.com/kingdom-two-crowns/): papel del monarca, contratación, construcción y campaña.
- [Portales](https://kingdomthegame.fandom.com/wiki/Portal), [arqueros](https://kingdomthegame.fandom.com/wiki/Archer) y [caballeros](https://kingdomthegame.fandom.com/wiki/Knight): asalto de tropas, protección de tiradores y defensa reactiva.
- [Contraataques](https://kingdomthegame.fandom.com/wiki/Counterattack_wave): distinguir defender un portal de responder a su destrucción.
- [Murallas](https://kingdomthegame.fandom.com/wiki/Wall): obras pagadas que ejecutan trabajadores; mejorar, reparar y ampliar el frente.

Se adaptan esos principios al GDD propio, conservando la identidad y los recursos originales del proyecto.

## Arte y verificación

Las unidades actuales utilizan `UnitSpriteLibrary` y sus nueve variantes; los edificios e iconos se consultan en las bibliotecas de arte. Las unidades de campo separan torso y piernas para caminar, retroceden al disparar y caen al ser desarmadas. Campamentos y brechas añaden brasas y energía animada. Constructores y recuperadores usan las variantes actuales en `assets/characters/units/`.

Fuentes: `entities/player/player.gd`, `systems/civic_system.gd`, `entities/structures/enemy_repeater.gd` y `systems/module_system.gd`. `commander_test` y las simulaciones de cinco distritos forman parte de las 67 ejecuciones de `tests/run_all.gd`. Validar mediante `tools/maintenance/validate.ps1`. Una simulación no mide la duración de una primera campaña humana.

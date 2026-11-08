# Changelog — BiciTaller

Todos los cambios importantes de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [0.6.1] - 2026-11-07

### Corregido

- Ojos y cejas de los clientes salían debajo de la boca (cerca del cuello) porque su altura se sumaba dos veces a la de la cabeza. Venía desde la versión original.

## [0.6.0] - 2026-11-07

### Añadido

- Sonido: 13 efectos (clic, timbre de bici, bombeo, eslabones de cadena, chirrido de freno, monedas, arreglo, combo, error, fallo, cliente que se va, fin de jornada) y música de fondo en bucle (La menor, 100 bpm), más baja durante la partida.
- Ajustes con interruptores separados de **Sonido** y **Música**, que se guardan.
- Todo el audio se genera con `python3 tools/gen_audio.py` (Python + numpy), sin samples de terceros.
- Tic-tac en el minijuego de frenos: suena más agudo cuando la aguja está en la zona verde.

## [0.5.0] - 2026-11-06

### Añadido

- Tipografía arcade Lilita One con contorno en títulos y números.
- Botones «caramelo» con relieve, brillo y efecto de hundirse al pulsar.
- HUD con pastillas de colores; la barra de paciencia parpadea en rojo al final.
- Taller nuevo: pared de ladrillo con friso, guirnalda de luces, ventana con haz de sol, cartel colgado y suelo con perspectiva.
- Bici con contornos, brillo, radios y pedales que giran; entra rodando y salta al arreglarla. Cada avería se ve: aire que se escapa, cadena caída, freno suelto.
- Clientes con contorno, ojos más expresivos y rebote de entrada.
- Efectos: monedas que suben (+30), cartel de combo, sacudida al fallar y confeti.
- Menú con ciudad al atardecer y un ciclista que cruza rodando.

## [0.4.0] - 2026-11-06

### Cambiado

- El juego ahora es **horizontal** (1280×720, apaisado): cliente a la izquierda, bici al centro, herramientas y minijuego a la derecha, con botones grandes para los pulgares.

### Añadido

- Botón «atrás» de Android (y Esc en el ordenador): cancela el minijuego, vuelve al menú o sale desde el menú.
- Los frenos muestran la zona verde y la aguja en una barra nueva.
- Código reordenado: pantallas con `enum`, constantes de reglas, estilos y dibujo compartidos en `ui.gd` y `gfx.gd`.

### Corregido

- Salir en pleno minijuego y empezar otra jornada ya no deja el panel del minijuego a la vista.
- Bombear y frenar responden al tocar (no al soltar).
- Al terminar de arreglar una bici ya no se marca la avería en rojo.
- Fondo del taller estático y vistas ocultas sin dibujar (menos batería).

## [0.3.0] - 2026-11-05

### Corregido

- 7 defectos de layout: HUD «Monedas/Vidas» ahora en horizontal (antes letra por letra en vertical), retratos con proporciones humanas, cartel «BiciTaller» separado del tablero de herramientas, nubes fuera del texto, firma «Hecho por yopcubita» legible, palmas con tronco grueso y 6 hojas, y arco de avería reducido.

## [0.2.0] - 2026-11-05

### Cambiado

- Arte renovado: clientes con cara, ropa y accesorio propio que cambian de expresión con la paciencia, bici detallada con radios y cadena, taller con ventana, tablero de herramientas y cartel, menú al atardecer y HUD con iconos y confeti al reparar.

## [0.1.0] - 2026-11-05

### Añadido

- Prototipo inicial: menú, jornada arcade con 8 clientes, 3 vidas, 3 averías con minijuegos (goma/bomba, cadena/llave, frenos/destornillador), monedas, propina y combo x2, guardado local.
- Créditos con la firma «Hecho por yopcubita».

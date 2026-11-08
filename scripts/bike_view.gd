extends Control
## La bici (y su avería), dibujada solo con código.
## Contorno oscuro en todas las piezas, neumáticos con aro metálico, cuadro con
## brillo, radios que giran, cadena con eslabones, frenos y sillín.
## Animaciones: entra rodando desde la izquierda, salta al arreglarla y cada
## avería se ve (aire que se escapa, cadena caída, pastilla de freno suelta).
## También sirve para el menú: con `spin` rueda sola y con `rider` lleva ciclista.
##
## La bici se apoya en la parte de abajo del control (GROUND_MARGIN), así que
## main.gd puede colocar el suelo del taller justo debajo.

const Gfx = preload("res://scripts/gfx.gd")

const GROUND_MARGIN := 22.0
const TIRE_WIDTH := 12.0
const INK := Color(0.12, 0.09, 0.1, 1)

var bike_color := Color(0.2, 0.45, 0.85, 1)
var fault := ""
## Rueda sola (menú) y ciclista encima.
var spin := false
var rider := false
var rider_skin := Color(0.85, 0.62, 0.45, 1)
var rider_shirt := Color(0.95, 0.75, 0.1, 1)
var rider_hair := Color(0.12, 0.08, 0.06, 1)

var _pulse := 0.0
var _wheel_angle := 0.0
var _slide := 0.0     # desplazamiento horizontal al entrar
var _hop := 0.0       # salto al celebrar (0..1, decae)
var _confetti: Array = []
var _confetti_time := 0.0

# Geometría de la bici; se recalcula al empezar cada _draw.
var _r := 0.0
var _rear := Vector2.ZERO
var _front := Vector2.ZERO
var _crank := Vector2.ZERO
var _ground_y := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


# No gastar batería dibujando cuando la pantalla del juego está oculta.
func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())


func ground_y() -> float:
	return size.y - GROUND_MARGIN


func set_bike(color: Color, fault_id: String) -> void:
	bike_color = color
	fault = fault_id
	queue_redraw()


## Entra rodando desde la izquierda (se llama con cada cliente nuevo).
func enter() -> void:
	_slide = -size.x * 0.85
	_wheel_angle = 0.0


func celebrate() -> void:
	_hop = 1.0
	_confetti.clear()
	var palette := [
		Color(0.9, 0.2, 0.15, 1), Color(1.0, 0.75, 0.1, 1),
		Color(0.1, 0.65, 0.55, 1), Color(0.9, 0.35, 0.55, 1),
		Color(0.2, 0.45, 0.85, 1),
	]
	for i in 40:
		_confetti.append({
			"pos": Vector2(randf_range(0.1, 0.9) * size.x, randf_range(-50.0, 20.0)),
			"vel": Vector2(randf_range(-40.0, 40.0), randf_range(100.0, 230.0)),
			"color": palette[i % palette.size()],
			"size": randf_range(7.0, 14.0),
			"spin": randf_range(-6.0, 6.0),
		})
	_confetti_time = 1.6


func _process(delta: float) -> void:
	_pulse += delta
	var moving := false
	if absf(_slide) > 0.5:
		# Frena suave al llegar; las ruedas giran mientras entra.
		_slide = lerpf(_slide, 0.0, 1.0 - exp(-7.0 * delta))
		_wheel_angle += delta * 9.0 * (absf(_slide) / maxf(size.x, 1.0) + 0.1) * 3.0
		moving = true
	else:
		_slide = 0.0
	if spin:
		_wheel_angle += delta * 9.0
		moving = true
	if _hop > 0.0:
		_hop = maxf(_hop - delta * 2.6, 0.0)
		moving = true
	if _confetti_time > 0.0:
		_confetti_time -= delta
		for p in _confetti:
			p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
			p["vel"] = (p["vel"] as Vector2) + Vector2(sin(_pulse * 5.0 + float(p["size"])) * 12.0 * delta, 0)
		moving = true
	elif not _confetti.is_empty():
		_confetti.clear()
		moving = true
	if fault != "" or moving:
		queue_redraw()


func _update_geometry() -> void:
	var w := size.x
	var h := size.y
	_r = minf(w * 0.16, h * 0.30)
	_ground_y = ground_y()
	var hop := -absf(sin(_hop * PI)) * 26.0 if _hop > 0.0 else 0.0
	var cy := _ground_y - _r - TIRE_WIDTH * 0.5 + hop
	_rear = Vector2(w * 0.27, cy)
	_front = Vector2(w * 0.73, cy)
	_crank = Vector2(w * 0.52, cy + _r * 0.15)


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	_update_geometry()
	draw_set_transform(Vector2(_slide, 0.0), 0.0, Vector2.ONE)
	_draw_bike()
	if rider:
		_draw_rider()
	_draw_fault()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_confetti()


func _wheel(center: Vector2, tint: Color) -> void:
	var r := _r
	# Neumático grueso con contorno, aro de color brillante y radios que giran.
	draw_arc(center, r, 0, TAU, 56, INK, TIRE_WIDTH + 4.0)
	draw_arc(center, r, 0, TAU, 56, Color(0.2, 0.2, 0.24, 1), TIRE_WIDTH)
	draw_arc(center, r - 6.0, 0, TAU, 56, Color(0.78, 0.8, 0.86, 1), 4.0)
	draw_arc(center, r - 9.0, 0, TAU, 56, tint, 3.0)
	for i in 14:
		var a := _wheel_angle + TAU * float(i) / 14.0
		draw_line(center, center + Vector2(cos(a), sin(a)) * (r - 10.0), Color(0.82, 0.84, 0.9, 0.9), 1.5)
	# Reflejo del neumático.
	draw_arc(center, r + 2.0, PI * 1.15, PI * 1.45, 12, Color(1, 1, 1, 0.28), 3.0)
	# Buje.
	draw_circle(center, 9.0, INK)
	draw_circle(center, 6.0, Color(0.75, 0.77, 0.83, 1))
	draw_circle(center + Vector2(-1.5, -1.5), 2.0, Color(1, 1, 1, 0.9))


func _tube(a: Vector2, b: Vector2, w: float) -> void:
	draw_line(a, b, INK, w + 4.0)
	draw_line(a, b, bike_color.darkened(0.3), w)
	draw_line(a + Vector2(0, -1), b + Vector2(0, -1), bike_color, w - 3.0)
	# Brillo a lo largo del tubo.
	var n := (b - a).normalized().orthogonal() * (w * 0.22)
	draw_line(a - n, b - n, bike_color.lightened(0.55), 1.6)


func _draw_bike() -> void:
	var w := size.x
	var r := _r
	var rear := _rear
	var front := _front
	var crank := _crank
	var cy := rear.y
	var dark := INK
	var metal := Color(0.7, 0.72, 0.78, 1)
	var shade := bike_color.darkened(0.35)
	var light := bike_color.lightened(0.3)
	# Sombra de la bici en el suelo (se encoge cuando salta).
	var lift := clampf((_ground_y - r - TIRE_WIDTH * 0.5 - cy) / 26.0, 0.0, 1.0) * -1.0
	var sh := 1.0 - absf(lift) * 0.3
	draw_colored_polygon(Gfx.ellipse(Vector2(w * 0.5, _ground_y + 4.0), w * 0.33 * sh, 10.0 * sh), Color(0, 0, 0, 0.2))
	# Guardafangos.
	draw_arc(rear, r + 8, PI * 1.08, PI * 1.92, 24, dark, 9.0)
	draw_arc(rear, r + 8, PI * 1.08, PI * 1.92, 24, shade, 5.0)
	draw_arc(front, r + 8, PI * 1.08, PI * 1.92, 24, dark, 9.0)
	draw_arc(front, r + 8, PI * 1.08, PI * 1.92, 24, shade, 5.0)
	_wheel(rear, light)
	_wheel(front, light)
	# Cuadro con contorno y brillo.
	var top := Vector2(w * 0.50, cy - r * 0.95)
	var seat := Vector2(w * 0.38, cy - r * 1.15)
	var bars := Vector2(w * 0.68, cy - r * 1.10)
	_tube(rear, crank, 6.0)
	_tube(crank, front, 6.0)
	_tube(seat, rear, 6.0)
	_tube(rear, top, 7.0)
	_tube(top, front, 7.0)
	_tube(top, seat, 7.0)
	_tube(bars, front, 6.0)
	# Faro delantero.
	draw_circle(bars + Vector2(28, -6), 9.0, dark)
	draw_circle(bars + Vector2(28, -6), 6.5, Color(1.0, 0.95, 0.6, 1))
	draw_circle(bars + Vector2(26, -8), 2.0, Color(1, 1, 1, 1))
	# Manubrio con puños.
	draw_line(bars, bars + Vector2(20, -16), dark, 9.0)
	draw_line(bars, bars + Vector2(20, -16), Color(0.55, 0.57, 0.62, 1), 5.0)
	draw_line(bars + Vector2(18, -16), bars + Vector2(36, -12), dark, 10.0)
	draw_line(bars + Vector2(20, -16), bars + Vector2(34, -12), Color(0.2, 0.2, 0.22, 1), 7.0)
	_draw_brake(front, bars)
	# Sillín marrón y tija.
	draw_line(seat, seat + Vector2(0, 12), dark, 8.0)
	draw_line(seat, seat + Vector2(0, 10), metal, 4.0)
	draw_line(seat + Vector2(-24, -10), seat + Vector2(6, -8), dark, 14.0)
	draw_line(seat + Vector2(-24, -10), seat + Vector2(6, -8), Color(0.55, 0.36, 0.17, 1), 9.0)
	draw_line(seat + Vector2(-20, -12), seat + Vector2(2, -10), Color(0.8, 0.58, 0.3, 1), 2.0)
	_draw_drivetrain(crank, rear)


## Pastilla de freno sobre la rueda delantera: floja y vibrando si la avería es de frenos.
func _draw_brake(front: Vector2, bars: Vector2) -> void:
	var loose := fault == "frenos"
	var wob := sin(_pulse * 18.0) * 3.0 if loose else 0.0
	var pad := front + Vector2(wob, -_r - 9.0)
	draw_line(bars + Vector2(30, -12), bars + Vector2(30 + 6, 14), INK, 4.0)  # cable
	draw_line(pad + Vector2(-12, -4), pad + Vector2(12, -4), INK, 8.0)
	draw_line(pad + Vector2(-11, -4), pad + Vector2(11, -4), Color(0.85, 0.2, 0.15, 1), 5.0)
	if loose:
		# Chispas y aire entre pastilla y llanta: el freno no agarra.
		for i in 3:
			var a := _pulse * 9.0 + float(i) * 2.1
			draw_line(pad + Vector2(sin(a) * 14.0, 4), pad + Vector2(sin(a) * 18.0, 12.0 + float(i) * 3.0), Color(1, 0.85, 0.2, 0.9), 2.5)


func _pedal_pos(sign_dir: float) -> Vector2:
	var a := _wheel_angle * 0.8 + (0.0 if sign_dir > 0.0 else PI) + 0.6
	return _crank + Vector2(cos(a), sin(a)) * 28.0


func _draw_drivetrain(crank: Vector2, rear: Vector2) -> void:
	var dark := INK
	var metal := Color(0.7, 0.72, 0.78, 1)
	# Plato con dientes.
	for i in 10:
		var a := _wheel_angle * 0.8 + TAU * float(i) / 10.0
		draw_line(crank + Vector2(cos(a), sin(a)) * 15, crank + Vector2(cos(a), sin(a)) * 21, dark, 5.0)
	draw_circle(crank, 16.0, dark)
	draw_circle(crank, 13.0, Color(0.4, 0.42, 0.48, 1))
	draw_circle(crank, 6.0, metal)
	# Piñón trasero.
	draw_circle(rear, 12.0, dark)
	draw_circle(rear, 8.0, Color(0.4, 0.42, 0.48, 1))
	draw_circle(rear, 4.0, metal)
	# Cadena: si la avería es "cadena", cuelga floja y fuera del piñón.
	var top_a := crank + Vector2(0, -14)
	var top_b := rear + Vector2(0, -12)
	var bot_a := crank + Vector2(0, 15)
	var bot_b := rear + Vector2(0, 13)
	if fault == "cadena":
		_chain(top_a, top_b, 4.0)
		_chain(bot_a, bot_b, 34.0 + sin(_pulse * 5.0) * 3.0)
	else:
		_chain(top_a, top_b, 0.0)
		_chain(bot_a, bot_b, 0.0)
	# Pedales (giran con la rueda) con su biela.
	for sd in [1.0, -1.0]:
		var p := _pedal_pos(sd)
		draw_line(crank, p, dark, 8.0)
		draw_line(crank, p, Color(0.55, 0.57, 0.62, 1), 4.0)
		draw_rect(Rect2(p + Vector2(-10, -4), Vector2(20, 8)), dark)
		draw_rect(Rect2(p + Vector2(-8, -2), Vector2(16, 4)), Color(0.35, 0.36, 0.4, 1))


## Tramo de cadena con eslabones; `sag` lo hace colgar en curva.
func _chain(a: Vector2, b: Vector2, sag: float) -> void:
	var steps := 9
	var prev := a
	for i in steps + 1:
		var t := float(i) / float(steps)
		var p := a.lerp(b, t) + Vector2(0, sag * 4.0 * t * (1.0 - t))
		if i > 0:
			draw_line(prev, p, INK, 6.0)
			draw_line(prev, p, Color(0.5, 0.5, 0.55, 1), 3.0)
		if i > 0 and i < steps:
			draw_circle(p, 3.0, Color(0.78, 0.8, 0.85, 1))
		prev = p


func _draw_rider() -> void:
	# Ciclista sencillo: pierna al pedal, torso inclinado, brazo al manubrio y cabeza.
	var w := size.x
	var seat := Vector2(w * 0.38, _rear.y - _r * 1.15)
	var bars := Vector2(w * 0.68, _rear.y - _r * 1.10)
	var hip := seat + Vector2(-10, -14)
	var shoulder := hip + Vector2(24, -_r * 0.7)
	var hand := bars + Vector2(30, -14)
	var skin := rider_skin
	var shirt := rider_shirt
	for sd in [-1.0, 1.0]:
		var foot := _pedal_pos(sd)
		var knee := hip.lerp(foot, 0.5) + Vector2(10, -8)
		draw_line(hip, knee, INK, 14.0)
		draw_line(knee, foot, INK, 12.0)
		draw_line(hip, knee, Color(0.2, 0.28, 0.5, 1), 10.0)
		draw_line(knee, foot, skin, 8.0)
		draw_circle(foot, 6.0, INK)
	draw_line(hip, shoulder, INK, 30.0)
	draw_line(hip, shoulder, shirt, 25.0)
	draw_line(shoulder, hand, INK, 12.0)
	draw_line(shoulder, hand, skin, 8.0)
	var head := shoulder + Vector2(8, -22)
	draw_circle(head, 20.0, INK)
	draw_circle(head, 17.0, skin)
	draw_arc(head + Vector2(-1, -2), 17.0, PI * 0.95, PI * 2.0, 16, rider_hair, 9.0)
	draw_circle(head + Vector2(7, 0), 2.5, INK)


func _draw_fault() -> void:
	if fault == "":
		return
	var r := _r
	var alpha := 0.55 + 0.45 * sin(_pulse * 6.0)
	var red := Color(0.95, 0.2, 0.15, alpha)
	var spot := _rear
	if fault == "goma":
		# La rueda trasera se desinfla: aro rojo, clavo y bocanadas de aire que salen.
		draw_arc(_rear, r + 10, PI * 0.15, PI * 0.85, 20, red, 6.0)
		var nail := _rear + Vector2(cos(PI * 0.42), sin(PI * 0.42)) * (r + 4.0)
		draw_line(nail, nail + Vector2(4, 14), INK, 5.0)
		draw_line(nail, nail + Vector2(4, 14), Color(0.75, 0.75, 0.8, 1), 2.5)
		for i in 4:
			var t := fposmod(_pulse * 1.3 + float(i) * 0.25, 1.0)
			var puff := nail + Vector2(-8 - t * 36.0, 4.0 - t * 22.0)
			draw_circle(puff, 4.0 + t * 7.0, Color(1, 1, 1, 0.65 * (1.0 - t)))
		spot = _rear + Vector2(0, -r - 34)
	elif fault == "cadena":
		draw_arc(_crank, 28, 0, TAU, 32, red, 5.0)
		spot = _crank + Vector2(0, -50)
	elif fault == "frenos":
		draw_arc(_front, r + 12, PI * 1.1, PI * 1.9, 32, red, 6.0)
		spot = _front + Vector2(0, -r - 38)
	# Distintivo "!" que late (el origen del texto es su esquina izquierda,
	# por eso se centra con un ancho fijo).
	var pop := 1.0 + 0.12 * sin(_pulse * 8.0)
	draw_circle(spot + Vector2(0, 2), 21.0 * pop, Color(0, 0, 0, 0.25))
	draw_circle(spot, 20.0 * pop, Color(1, 0.95, 0.3, 1))
	draw_arc(spot, 20.0 * pop, 0, TAU, 32, INK, 4.0)
	Gfx.FONT.draw_string(get_canvas_item(), spot + Vector2(-20, 11),
		"!", HORIZONTAL_ALIGNMENT_CENTER, 40, 32, INK)


func _draw_confetti() -> void:
	if _confetti_time <= 0.0:
		return
	for p in _confetti:
		var pos := p["pos"] as Vector2
		var s := float(p["size"])
		var tilt := float(p["spin"]) * _pulse * 3.0
		var c := p["color"] as Color
		draw_set_transform(pos, tilt, Vector2.ONE)
		draw_rect(Rect2(Vector2(-s * 0.5, -s * 0.3), Vector2(s, s * 0.6)), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

extends Control
## Retrato del cliente, dibujado solo con código.
## Cara con expresión según la paciencia (0 contento, 1 preocupado, 2 bravo),
## pelo o sombrero propio, ropa de su color y un accesorio. Sombra en los pies.
## Parpadea cada pocos segundos y se balancea un poco (barato: 30 FPS).

const Gfx = preload("res://scripts/gfx.gd")

## El retrato se dibuja en un "espacio de diseño" fijo y se escala para llenar
## el control, así se ve igual de bien en la columna del cliente (horizontal)
## sea cual sea el tamaño de pantalla.
const DESIGN_W := 210.0
const DESIGN_H := 190.0
const INK := Color(0.12, 0.09, 0.1, 1)
const HEAD_R := 36.0
const BODY_W := HEAD_R * 3.0

var client := {}
var mood := 0
var _pulse := 0.0
var _pop_t := 1.0
var _shirt_style: StyleBoxFlat


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shirt_style = StyleBoxFlat.new()
	_shirt_style.set_corner_radius_all(18)
	_shirt_style.shadow_color = Color(0, 0, 0, 0.25)
	_shirt_style.shadow_size = 4
	_shirt_style.shadow_offset = Vector2(0, 3)


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


# No gastar batería dibujando cuando la pantalla del juego está oculta.
func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())


## Rebote de entrada cuando llega un cliente nuevo.
func pop() -> void:
	_pop_t = 0.0


func set_client(c: Dictionary, mood_value: int) -> void:
	client = c
	mood = mood_value
	queue_redraw()


func set_mood(m: int) -> void:
	if m != mood:
		mood = m
		queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	_pop_t = minf(_pop_t + delta / 0.45, 1.0)
	queue_redraw()


func _skin() -> Color:
	return client.get("piel", Color(0.85, 0.65, 0.5, 1))


func _shirt() -> Color:
	return client.get("color", Color(0.2, 0.45, 0.85, 1))


func _hair() -> Color:
	return client.get("pelo", Color(0.15, 0.1, 0.08, 1))


func _hat() -> String:
	return str(client.get("sombrero", "largo"))


func _accessory() -> String:
	return str(client.get("accesorio", "ninguno"))


func _ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_colored_polygon(Gfx.ellipse(center, rx, ry), col)


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0 or client.is_empty():
		return
	# Escala el espacio de diseño al control y lo centra.
	var s := minf(size.x / DESIGN_W, size.y / DESIGN_H)
	var origin := Vector2((size.x - DESIGN_W * s) * 0.5, (size.y - DESIGN_H * s) * 0.5)
	# Rebote (ease-out-back) alrededor de los pies.
	var k := 1.0
	if _pop_t < 1.0:
		var u := _pop_t - 1.0
		k = 0.55 + 0.45 * (1.0 + 2.70158 * u * u * u + 1.70158 * u * u)
	var pivot := Vector2(size.x * 0.5, origin.y + DESIGN_H * s)
	draw_set_transform(pivot * (1.0 - k) + origin * k, 0.0, Vector2(s * k, s * k))
	var w := DESIGN_W
	var h := DESIGN_H
	var cx := w * 0.5
	var bob := sin(_pulse * 2.0) * 2.0
	# Proporciones humanas: cabeza de ~72 px de diámetro, torso de ~108 px
	# (1,5 cabezas), hombros redondeados, cuello visible y brazos desde los hombros.
	var head_r := HEAD_R
	var half_body := BODY_W * 0.5
	var head := Vector2(cx, h * 0.24 + bob)
	var body_top := h * 0.47 + bob
	var body_rect := Rect2(cx - half_body, body_top, half_body * 2.0, h - body_top - 4)
	# Sombra bajo los pies.
	_ellipse(Vector2(cx, h * 0.97), half_body * 1.15, 8, Color(0, 0, 0, 0.18))
	# Brazos: salen de los hombros y llegan a la cadera.
	var shirt := _shirt()
	var shoulder_l := Vector2(cx - half_body * 0.88, body_top + 14)
	var shoulder_r := Vector2(cx + half_body * 0.88, body_top + 14)
	var hand_l := Vector2(cx - half_body - 16, body_top + h * 0.34)
	var hand_r := Vector2(cx + half_body + 16, body_top + h * 0.34)
	draw_line(shoulder_l, hand_l, INK, 18.0)
	draw_line(shoulder_r, hand_r, INK, 18.0)
	draw_line(shoulder_l, hand_l, shirt.darkened(0.15), 13.0)
	draw_line(shoulder_r, hand_r, shirt.darkened(0.15), 13.0)
	# Manos.
	draw_circle(hand_l + Vector2(0, 6), 11, INK)
	draw_circle(hand_r + Vector2(0, 6), 11, INK)
	draw_circle(hand_l + Vector2(0, 6), 8, _skin())
	draw_circle(hand_r + Vector2(0, 6), 8, _skin())
	# Torso (camisa del color del cliente) con cuello en V y botones.
	_shirt_style.bg_color = shirt
	_shirt_style.border_color = INK
	_shirt_style.set_border_width_all(3)
	draw_style_box(_shirt_style, body_rect)
	var collar := shirt.darkened(0.3)
	draw_line(Vector2(cx - 13, body_top + 2), Vector2(cx, body_top + 16), collar, 3.0)
	draw_line(Vector2(cx + 13, body_top + 2), Vector2(cx, body_top + 16), collar, 3.0)
	draw_circle(Vector2(cx, body_top + 34), 3, shirt.darkened(0.35))
	draw_circle(Vector2(cx, body_top + 58), 3, shirt.darkened(0.35))
	# Cuello.
	draw_rect(Rect2(cx - 11, head.y + head_r - 6, 22, 18), _skin())
	# Cabeza.
	draw_circle(head + Vector2(-head_r, 2), 9, INK)
	draw_circle(head + Vector2(head_r, 2), 9, INK)
	draw_circle(head, head_r + 3.0, INK)
	draw_circle(head, head_r, _skin())
	# Orejas.
	draw_circle(head + Vector2(-head_r, 2), 6, _skin())
	draw_circle(head + Vector2(head_r, 2), 6, _skin())
	# Luz suave en la frente.
	draw_circle(head + Vector2(-head_r * 0.35, -head_r * 0.4), head_r * 0.35, Color(1, 1, 1, 0.12))
	_hair_and_hat(head, head_r)
	_face(head, head_r)
	_accessory_draw(cx, body_top, body_rect)


func _hair_and_hat(head: Vector2, r: float) -> void:
	var hair := _hair()
	match _hat():
		"largo":
			# Melena: casquete y mechones a los lados.
			draw_arc(head + Vector2(0, -4), r, PI * 0.95, PI * 2.05, 24, hair, r * 0.55)
			draw_circle(head + Vector2(-r * 0.95, r * 0.25), r * 0.28, hair)
			draw_circle(head + Vector2(r * 0.95, r * 0.25), r * 0.28, hair)
		"canas":
			draw_arc(head + Vector2(0, -6), r, PI * 1.05, PI * 1.95, 20, Color(0.92, 0.92, 0.92, 1), 7.0)
		"gorra":
			draw_arc(head + Vector2(0, -4), r * 0.95, PI, TAU, 20, Color(0.95, 0.5, 0.1, 1), r * 0.6)
			draw_rect(Rect2(head.x - r * 0.2, head.y - r * 0.75, r * 1.7, 9), Color(0.95, 0.5, 0.1, 1))
			draw_circle(head + Vector2(0, -r * 0.95), 4, Color(1, 1, 1, 1))
		"yarey":
			# Sombrero de yarey: ala ancha y copa.
			_ellipse(head + Vector2(0, -r * 0.55), r * 1.35, r * 0.28, Color(0.85, 0.7, 0.4, 1))
			draw_arc(head + Vector2(0, -r * 0.55), r * 0.62, PI, TAU, 20, Color(0.8, 0.65, 0.35, 1), r * 0.6)
			draw_arc(head + Vector2(0, -r * 0.45), r * 0.62, PI * 1.05, PI * 1.95, 16, Color(0.4, 0.25, 0.1, 1), 4.0)
		"gorro":
			# Gorro de panadero: alto y blanco.
			draw_circle(head + Vector2(-r * 0.4, -r * 0.95), r * 0.32, Color(1, 1, 1, 1))
			draw_circle(head + Vector2(r * 0.35, -r * 1.0), r * 0.34, Color(1, 1, 1, 1))
			draw_circle(head + Vector2(0, -r * 1.05), r * 0.36, Color(1, 1, 1, 1))
			draw_rect(Rect2(head.x - r * 0.95, head.y - r * 0.85, r * 1.9, r * 0.3), Color(0.95, 0.95, 0.95, 1))
		"casco":
			draw_arc(head + Vector2(0, -4), r * 1.02, PI * 0.98, PI * 2.02, 24, Color(0.85, 0.15, 0.2, 1), r * 0.62)
			draw_line(head + Vector2(-r * 0.9, 0), head + Vector2(-r * 0.45, r * 0.75), Color(0.2, 0.2, 0.2, 1), 3.0)
			draw_line(head + Vector2(r * 0.9, 0), head + Vector2(r * 0.45, r * 0.75), Color(0.2, 0.2, 0.2, 1), 3.0)
		"moño":
			draw_arc(head + Vector2(0, -4), r, PI * 0.95, PI * 2.05, 24, hair, r * 0.5)
			draw_circle(head + Vector2(0, -r * 1.05), r * 0.34, hair)
		"trenza":
			draw_arc(head + Vector2(0, -4), r, PI * 0.95, PI * 2.05, 24, hair, r * 0.55)
			for i in 3:
				draw_circle(head + Vector2(r * 1.0, r * (0.35 + float(i) * 0.35)), r * 0.2, hair)
		"lazo":
			draw_arc(head + Vector2(0, -4), r, PI * 0.95, PI * 2.05, 24, hair, r * 0.55)
			# Lazo rosado en el pelo.
			var bx := head.x + r * 0.75
			var by := head.y - r * 0.75
			draw_colored_polygon(PackedVector2Array([Vector2(bx, by), Vector2(bx - 18, by - 10), Vector2(bx - 18, by + 10)]), Color(0.9, 0.35, 0.55, 1))
			draw_colored_polygon(PackedVector2Array([Vector2(bx, by), Vector2(bx + 18, by - 10), Vector2(bx + 18, by + 10)]), Color(0.9, 0.35, 0.55, 1))
			draw_circle(Vector2(bx, by), 5, Color(0.75, 0.2, 0.4, 1))
	# Flor en el pelo (accesorio de Lili).
	if _accessory() == "flor":
		var fx := head.x - r * 0.7
		var fy := head.y - r * 0.8
		for k in 5:
			var a := TAU * float(k) / 5.0
			draw_circle(Vector2(fx + cos(a) * 7, fy + sin(a) * 7), 4, Color(1.0, 0.6, 0.75, 1))
		draw_circle(Vector2(fx, fy), 4, Color(1.0, 0.85, 0.2, 1))


func _face(head: Vector2, r: float) -> void:
	var blink := fmod(_pulse, 3.2) < 0.12
	var eye_y := -r * 0.05   # desplazamiento respecto al centro de la cabeza (no una altura absoluta)
	var eye_dx := r * 0.38
	var dark := Color(0.12, 0.1, 0.1, 1)
	# Rubor.
	draw_circle(head + Vector2(-r * 0.62, r * 0.3), r * 0.16, Color(0.95, 0.5, 0.45, 0.35))
	draw_circle(head + Vector2(r * 0.62, r * 0.3), r * 0.16, Color(0.95, 0.5, 0.45, 0.35))
	# Ojos (o líneas si parpadea).
	for sx in [-1.0, 1.0]:
		var eye := head + Vector2(sx * eye_dx, eye_y)
		if blink:
			draw_line(eye + Vector2(-5, 0), eye + Vector2(5, 0), dark, 2.5)
		else:
			draw_circle(eye, 8.0, INK)
			draw_circle(eye, 6.8, Color(1, 1, 1, 1))
			var look := Vector2(sin(_pulse * 0.9) * 1.6, 0.8)
			draw_circle(eye + look, 4.4, dark)
			draw_circle(eye + look + Vector2(1.6, -1.8), 1.7, Color(1, 1, 1, 1))
	# Cejas según el ánimo.
	var brow_y := eye_y - r * 0.40
	if mood == 2:
		# Bravo: cejas enojadas, inclinadas hacia el centro.
		draw_line(head + Vector2(-eye_dx - 6, brow_y - 4), head + Vector2(-eye_dx + 6, brow_y + 3), dark, 3.0)
		draw_line(head + Vector2(eye_dx - 6, brow_y + 3), head + Vector2(eye_dx + 6, brow_y - 4), dark, 3.0)
	elif mood == 1:
		# Preocupado: cejas levantadas.
		draw_line(head + Vector2(-eye_dx - 6, brow_y + 2), head + Vector2(-eye_dx + 6, brow_y - 3), dark, 2.5)
		draw_line(head + Vector2(eye_dx - 6, brow_y - 3), head + Vector2(eye_dx + 6, brow_y + 2), dark, 2.5)
	else:
		draw_line(head + Vector2(-eye_dx - 6, brow_y), head + Vector2(-eye_dx + 6, brow_y), dark, 2.5)
		draw_line(head + Vector2(eye_dx - 6, brow_y), head + Vector2(eye_dx + 6, brow_y), dark, 2.5)
	# Boca según el ánimo.
	var mouth := head + Vector2(0, r * 0.42)
	if mood == 0:
		draw_arc(mouth + Vector2(0, -4), r * 0.32, PI * 0.15, PI * 0.85, 16, dark, 3.0)
	elif mood == 1:
		draw_line(mouth + Vector2(-7, 0), mouth + Vector2(7, 0), dark, 3.0)
		# Gota de sudor.
		var drop := head + Vector2(r * 0.85, -r * 0.35)
		draw_circle(drop, 4, Color(0.4, 0.7, 1.0, 0.9))
		draw_colored_polygon(PackedVector2Array([drop + Vector2(-4, -2), drop + Vector2(4, -2), drop + Vector2(0, -11)]), Color(0.4, 0.7, 1.0, 0.9))
	else:
		draw_arc(mouth + Vector2(0, 10), r * 0.3, PI * 1.15, PI * 1.85, 16, dark, 3.0)
		# Vena de enojo en la frente.
		var v := head + Vector2(r * 0.55, -r * 0.55)
		draw_line(v + Vector2(-5, 0), v + Vector2(5, 0), Color(0.85, 0.15, 0.15, 1), 2.5)
		draw_line(v + Vector2(0, -5), v + Vector2(0, 5), Color(0.85, 0.15, 0.15, 1), 2.5)


func _accessory_draw(cx: float, body_top: float, body_rect: Rect2) -> void:
	var acc := _accessory()
	var y := body_top + 18
	if acc == "libros":
		# Pila de libros en la mano.
		var bx := cx + body_rect.size.x * 0.5 + 4
		draw_rect(Rect2(bx - 4, y + 22, 34, 9), Color(0.2, 0.4, 0.8, 1))
		draw_rect(Rect2(bx - 2, y + 12, 30, 9), Color(0.85, 0.25, 0.1, 1))
		draw_rect(Rect2(bx, y + 2, 26, 9), Color(0.15, 0.6, 0.35, 1))
	elif acc == "mochila":
		# Mochila naranja colgando del hombro.
		var bx := cx - body_rect.size.x * 0.5 - 26
		draw_rect(Rect2(bx, y + 6, 26, 34), Color(0.9, 0.45, 0.1, 1))
		draw_arc(Vector2(bx + 13, y + 6), 13, PI, TAU, 12, Color(0.9, 0.45, 0.1, 1), 10.0)
		draw_rect(Rect2(bx + 5, y + 18, 16, 12), Color(0.7, 0.3, 0.05, 1))
	elif acc == "baston":
		# Bastón del abuelo.
		var bx := cx + body_rect.size.x * 0.5 + 16
		draw_line(Vector2(bx, y), Vector2(bx, y + 78), Color(0.5, 0.35, 0.15, 1), 5.0)
		draw_arc(Vector2(bx - 7, y + 2), 8, PI * 0.9, PI * 2.0, 12, Color(0.5, 0.35, 0.15, 1), 5.0)
	elif acc == "flor":
		# Flor en el pelo (se dibuja cerca de la cabeza, no del cuerpo).
		pass
	elif acc == "botella":
		# Botellita de agua.
		var bx := cx - body_rect.size.x * 0.5 - 14
		draw_rect(Rect2(bx, y + 16, 12, 22), Color(0.3, 0.65, 0.95, 1))
		draw_rect(Rect2(bx + 3, y + 10, 6, 7), Color(0.3, 0.65, 0.95, 1))
		draw_rect(Rect2(bx + 2, y + 6, 8, 5), Color(0.15, 0.4, 0.7, 1))
	elif acc == "bolsa":
		# Bolsa de compras.
		var bx := cx + body_rect.size.x * 0.5 + 2
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx, y + 18), Vector2(bx + 30, y + 18),
			Vector2(bx + 26, y + 48), Vector2(bx + 4, y + 48)]), Color(0.95, 0.8, 0.3, 1))
		draw_arc(Vector2(bx + 15, y + 18), 9, PI, TAU, 12, Color(0.6, 0.45, 0.1, 1), 3.0)
	elif acc == "cesta_pan":
		# Cesta con panes.
		var bx := cx - body_rect.size.x * 0.5 - 34
		draw_rect(Rect2(bx, y + 20, 34, 20), Color(0.6, 0.4, 0.15, 1))
		draw_line(Vector2(bx, y + 30), Vector2(bx + 34, y + 30), Color(0.45, 0.28, 0.08, 1), 2.0)
		_ellipse(Vector2(bx + 8, y + 16), 8, 6, Color(0.85, 0.65, 0.35, 1))
		_ellipse(Vector2(bx + 18, y + 13), 8, 6, Color(0.9, 0.7, 0.4, 1))
		_ellipse(Vector2(bx + 27, y + 16), 8, 6, Color(0.85, 0.65, 0.35, 1))

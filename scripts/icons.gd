extends RefCounted
## Iconos procedurales: se rasterizan a ImageTexture en tiempo de ejecución.
## Sin assets externos. Se usan en los botones de herramientas y en el HUD.

const S := 64


static func _new_image() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)


static func _px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < S and y >= 0 and y < S:
		img.set_pixel(x, y, col)


static func _disc(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	var rr := int(ceil(r))
	for yy in range(int(cy) - rr, int(cy) + rr + 1):
		for xx in range(int(cx) - rr, int(cx) + rr + 1):
			var dx := float(xx) - cx + 0.5
			var dy := float(yy) - cy + 0.5
			if dx * dx + dy * dy <= r * r:
				_px(img, xx, yy, col)


static func _line(img: Image, a: Vector2, b: Vector2, width: float, col: Color) -> void:
	var steps := int(a.distance_to(b) * 2.0) + 1
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		_disc(img, p.x, p.y, width * 0.5, col)


static func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, col)


static func _to_texture(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


static func pump() -> ImageTexture:
	var img := _new_image()
	var dark := Color(0.15, 0.15, 0.18, 1)
	var steel := Color(0.6, 0.62, 0.68, 1)
	var red := Color(0.85, 0.25, 0.1, 1)
	# Mango (barra horizontal con puños).
	_rect(img, 12, 8, 40, 7, dark)
	_disc(img, 13, 11, 5, red)
	_disc(img, 51, 11, 5, red)
	# Cuerpo de la bomba.
	_rect(img, 28, 15, 8, 30, steel)
	_rect(img, 30, 15, 2, 30, Color(0.85, 0.87, 0.9, 1))
	# Base.
	_rect(img, 20, 45, 24, 6, dark)
	# Manguera y boquilla.
	_line(img, Vector2(36, 38), Vector2(48, 46), 4.0, dark)
	_line(img, Vector2(48, 46), Vector2(52, 54), 4.0, dark)
	_rect(img, 50, 52, 6, 7, red)
	return _to_texture(img)


static func wrench() -> ImageTexture:
	var img := _new_image()
	var steel := Color(0.65, 0.67, 0.72, 1)
	var steel_dark := Color(0.4, 0.42, 0.47, 1)
	var clear := Color(0, 0, 0, 0)
	# Boca abierta (anillo con mordida).
	_disc(img, 22, 20, 14, steel)
	_disc(img, 22, 20, 8, clear)
	_rect(img, 22, 3, 16, 12, clear)
	# Mango.
	_line(img, Vector2(28, 30), Vector2(50, 54), 9.0, steel)
	_line(img, Vector2(28, 30), Vector2(50, 54), 4.0, steel_dark)
	return _to_texture(img)


static func screwdriver() -> ImageTexture:
	var img := _new_image()
	var red := Color(0.85, 0.25, 0.1, 1)
	var red_dark := Color(0.6, 0.15, 0.08, 1)
	var steel := Color(0.65, 0.67, 0.72, 1)
	# Mango rojo.
	_rect(img, 24, 6, 16, 20, red)
	_disc(img, 32, 6, 8, red)
	_disc(img, 32, 26, 8, red)
	_rect(img, 28, 10, 3, 12, red_dark)
	# Vástago y punta.
	_line(img, Vector2(32, 28), Vector2(32, 48), 5.0, steel)
	_line(img, Vector2(32, 48), Vector2(32, 56), 5.0, Color(0.35, 0.37, 0.4, 1))
	return _to_texture(img)


static func coin() -> ImageTexture:
	var img := _new_image()
	var gold := Color(1.0, 0.78, 0.15, 1)
	var gold_light := Color(1.0, 0.88, 0.45, 1)
	var gold_dark := Color(0.75, 0.5, 0.05, 1)
	_disc(img, 32, 32, 26, gold_dark)
	_disc(img, 32, 32, 23, gold)
	_disc(img, 32, 32, 18, gold_light)
	# Símbolo $.
	_rect(img, 30, 18, 4, 28, gold_dark)
	_rect(img, 23, 20, 18, 4, gold_dark)
	_rect(img, 23, 30, 18, 4, gold_dark)
	_rect(img, 23, 40, 18, 4, gold_dark)
	return _to_texture(img)


static func heart() -> ImageTexture:
	var img := _new_image()
	var red := Color(0.9, 0.15, 0.25, 1)
	var red_light := Color(1.0, 0.45, 0.5, 1)
	_disc(img, 22, 22, 11, red)
	_disc(img, 42, 22, 11, red)
	for yy in range(24, 54):
		var half_w := 21.0 - float(yy - 24) * 0.68
		if half_w < 1.0:
			half_w = 1.0
		_rect(img, int(32 - half_w), yy, int(half_w * 2.0), 1, red)
	_disc(img, 25, 18, 4, red_light)
	return _to_texture(img)


static func spark() -> ImageTexture:
	var img := _new_image()
	var col := Color(1.0, 0.85, 0.25, 1)
	for yy in range(4, 60):
		var half_w := 2.0 + 11.0 * (1.0 - absf(float(yy) - 32.0) / 28.0)
		if half_w < 1.0:
			half_w = 1.0
		_rect(img, int(32 - half_w), yy, int(half_w * 2.0), 1, col)
	return _to_texture(img)

extends RefCounted
## Ayudas para construir la interfaz por código: paleta, etiquetas, botones y barras.
## Así main.gd solo describe la pantalla y no repite estilos.

const RED := Color(0.85, 0.25, 0.1, 1)
const TEAL := Color(0.05, 0.55, 0.5, 1)
const GRAY := Color(0.5, 0.5, 0.55, 1)
const INK := Color(0.25, 0.25, 0.25, 1)
const MUTED := Color(0.4, 0.4, 0.4, 1)
const BROWN := Color(0.4, 0.3, 0.2, 1)
const CREAM := Color(0.98, 0.93, 0.83, 1)
const SAND := Color(0.96, 0.90, 0.78, 1)
const TRACK := Color(0.2, 0.15, 0.12, 0.85)
const OUTLINE := Color(0.3, 0.1, 0.06, 1)


static func gradient_texture(top: Color, bottom: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, top)
	grad.set_color(1, bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 8
	tex.height = 512
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	return tex


static func make_label(text: String, font_size: int, color: Color, shadow := false,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, outline: int = 0) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if outline > 0:
		# Contorno grueso oscuro: las letras "saltan" del fondo, estilo arcade.
		label.add_theme_color_override("font_outline_color", OUTLINE)
		label.add_theme_constant_override("outline_size", outline)
	if shadow:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 3)
	return label


## Botón "caramelo": cuerpo de color, borde inferior grueso (relieve) y sombra.
## Al pulsarlo se hunde: el relieve baja y el texto se desplaza.
static func button_style(c: Color, pressed := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(20)
	sb.border_color = c.darkened(0.38)
	sb.set_border_width_all(3)
	sb.border_width_bottom = 3 if pressed else 9
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 14 if pressed else 8
	sb.content_margin_bottom = 8 if pressed else 12
	sb.shadow_color = Color(0, 0, 0, 0.30)
	sb.shadow_size = 4 if pressed else 8
	sb.shadow_offset = Vector2(0, 2 if pressed else 5)
	return sb


static func make_button(text: String, font_size: int = 26, accent: Color = RED) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 68)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.85, 1))
	button.add_theme_color_override("font_outline_color", accent.darkened(0.55))
	button.add_theme_constant_override("outline_size", 6)
	button.add_theme_stylebox_override("normal", button_style(accent))
	button.add_theme_stylebox_override("hover", button_style(accent.lightened(0.10)))
	button.add_theme_stylebox_override("pressed", button_style(accent.darkened(0.10), true))
	button.add_theme_stylebox_override("disabled", button_style(Color(0.6, 0.6, 0.6, 1)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# Sonido de clic al tocar (los botones de minijuego tienen su propio sonido).
	button.button_down.connect(func() -> void:
		if not button.has_meta("silent"):
			Sfx.play("click"))
	# Brillo: franja blanca translúcida en la mitad de arriba.
	var gloss := Panel.new()
	gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gloss.anchor_right = 1.0
	gloss.anchor_bottom = 0.5
	gloss.offset_left = 10
	gloss.offset_right = -10
	gloss.offset_top = 5
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(1, 1, 1, 0.16)
	gs.corner_radius_top_left = 14
	gs.corner_radius_top_right = 14
	gs.corner_radius_bottom_left = 6
	gs.corner_radius_bottom_right = 6
	gloss.add_theme_stylebox_override("panel", gs)
	button.add_child(gloss)
	return button


## Tarjeta translúcida para agrupar contenido sobre el taller.
static func card_style(alpha: float = 0.92) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.975, 0.90, alpha)
	sb.set_corner_radius_all(24)
	sb.border_color = Color(0.62, 0.3, 0.12, 1)
	sb.set_border_width_all(5)
	sb.shadow_color = Color(0, 0, 0, 0.32)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	sb.set_content_margin_all(14)
	return sb


## Pastilla redonda de color para el HUD (monedas, vidas, día...).
static func pill_style(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(22)
	sb.border_color = c.darkened(0.4)
	sb.set_border_width_all(3)
	sb.border_width_bottom = 5
	sb.content_margin_left = 14
	sb.content_margin_right = 16
	sb.content_margin_top = 3
	sb.content_margin_bottom = 4
	return sb


static func make_card(alpha: float = 0.92) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style(alpha))
	return card


## Barra de progreso de un solo color (minijuegos).
static func make_bar(height: float, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	var bg := StyleBoxFlat.new()
	bg.bg_color = TRACK
	bg.set_corner_radius_all(int(height * 0.5))
	bg.border_color = Color(0.1, 0.06, 0.04, 1)
	bg.set_border_width_all(2)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(int(height * 0.5))
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## Barra de paciencia: degradado verde → amarillo → rojo.
static func make_patience_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 26)
	var bg := StyleBoxFlat.new()
	bg.bg_color = TRACK
	bg.set_corner_radius_all(13)
	bg.border_color = Color(0.1, 0.06, 0.04, 1)
	bg.set_border_width_all(3)
	bar.add_theme_stylebox_override("background", bg)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.15, 0.75, 0.3, 1))
	grad.set_color(1, Color(0.9, 0.15, 0.15, 1))
	grad.add_point(0.5, Color(1.0, 0.85, 0.2, 1))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 16
	tex.fill_from = Vector2(0, 0.5)
	tex.fill_to = Vector2(1, 0.5)
	var fill := StyleBoxTexture.new()
	fill.texture = tex
	fill.texture_margin_left = 3
	fill.texture_margin_right = 3
	fill.texture_margin_top = 3
	fill.texture_margin_bottom = 3
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func spacer(parent: Container, min_height: float = 0.0) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, min_height)
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(s)
	return s

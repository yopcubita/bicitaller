extends Control
## BiciTaller v0.4 — pantalla principal en horizontal (1280x720): menú, jornada y resultados.
## Todo el arte es código (BikeView, ClientView, fondos) y toda la interfaz se
## construye aquí, para que el proyecto sea una sola escena fácil de revisar y exportar.
##
## Pantalla de juego (tres columnas):
##   izquierda = cliente y su síntoma | centro = la bici | derecha = herramientas / minijuego.

const Data = preload("res://scripts/data.gd")
const UI = preload("res://scripts/ui.gd")
const Icons = preload("res://scripts/icons.gd")
const BikeViewScript = preload("res://scripts/bike_view.gd")
const ClientViewScript = preload("res://scripts/client_view.gd")
const SceneBgScript = preload("res://scripts/scene_bg.gd")
const WorkshopBgScript = preload("res://scripts/workshop_bg.gd")
const ZoneBarScript = preload("res://scripts/zone_bar.gd")

# Reglas de la jornada.
const MAX_LIVES := 3
const BASE_PAY := 20
const TIP_PAY := 10
const TIP_PATIENCE_MIN := 50.0   # propina si la paciencia queda por encima
const COMBO_STREAK := 3          # racha que duplica el pago
const WRONG_TOOL_PATIENCE := 18.0
const FAIL_PATIENCE := 15.0
const BIKES_PER_DAY := 5
const TWO_FAULTS_AFTER := 3      # tras esta cantidad de bicis llegan con 2 averías
const NEXT_CLIENT_DELAY := 1.2

# Minijuegos.
const PUMP_PER_TAP := 9.0
const NEEDLE_SPEED := 75.0
const BRAKE_ZONE_MIN := 45.0
const BRAKE_ZONE_MAX := 75.0
const TIME_GOMA := 10.0
const TIME_CADENA := 12.0
const TIME_FRENOS := 15.0

enum Screen { MENU, HOWTO, SETTINGS, CREDITS, GAME, RESULT }

var screen: Screen = Screen.MENU

# Partida.
var lives := MAX_LIVES
var coins_run := 0
var bikes_fixed := 0
var streak := 0
var best_streak_run := 0
var patience := 100.0
var current_client := {}
var fault_ids: Array = []
var current_fault_index := 0
var waiting_next := false
var waiting_timer := 0.0
var last_client_index := -1

# Minijuego activo.
var mg_active := false
var mg_type := ""
var mg_time_left := 0.0
var mg_time_max := 10.0
var mg_progress := 0.0
var mg_chain_step := 0
var mg_needle := 0.0
var mg_needle_dir := 1.0
var mg_holding := false
var _tick_time := 0.0

# Paneles y controles.
var panels := {}
var menu_stats_label: Label
var vib_button: Button
var sound_button: Button
var music_button: Button

var workshop_bg: Control
var hud_day: Label
var hud_coins: Label
var hud_lives: Label
var hud_combo: Label
var hud_combo_pill: PanelContainer
var menu_rider: Control
var _menu_time := 0.0
var _time := 0.0
var patience_bar: ProgressBar
var client_label: Label
var symptom_label: Label
var client_view: Control
var bike_view: Control
var message_label: Label
var tools_box: VBoxContainer
var _last_mood := 0

var mg_box: VBoxContainer
var mg_title: Label
var mg_info: Label
var mg_bar: ProgressBar
var zone_bar: Control
var mg_time_bar: ProgressBar
var mg_action: Button
var mg_chain_box: GridContainer

var result_coins: Label
var result_bikes: Label
var result_streak: Label
var result_best: Label


func _ready() -> void:
	_build_ui()
	_show_panel(Screen.MENU)


# ------------------------------------------------------------------ Navegación y botón atrás

func _notification(what: int) -> void:
	# Botón "atrás" de Android (config/quit_on_go_back=false en project.godot).
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_requested()


func _unhandled_key_input(event: InputEvent) -> void:
	# Esc en el ordenador hace lo mismo que "atrás" en el teléfono.
	if event.is_action_pressed("ui_cancel"):
		_on_back_requested()


func _on_back_requested() -> void:
	match screen:
		Screen.MENU:
			get_tree().quit()
		Screen.GAME:
			if mg_active:
				_on_mg_cancel()
			else:
				_on_quit_to_menu()
		_:
			_show_panel(Screen.MENU)


func _show_panel(target: Screen) -> void:
	for key in panels:
		panels[key].visible = key == target
	screen = target
	Sfx.set_in_game(target == Screen.GAME)
	match target:
		Screen.MENU:
			menu_stats_label.text = "Monedas totales: %d\nMejor jornada: %d bicis\nMejor racha: %d" \
				% [Save.total_coins, Save.best_bikes, Save.best_streak]
		Screen.SETTINGS:
			_update_settings_labels()
		Screen.GAME:
			call_deferred("_sync_workshop")


# ------------------------------------------------------------------ UI base

func _make_panel(bg: Color, scene: String = "") -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	if scene == "workshop":
		workshop_bg = WorkshopBgScript.new()
		workshop_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.add_child(workshop_bg)
	else:
		var tex_rect := TextureRect.new()
		tex_rect.texture = UI.gradient_texture(bg.lightened(0.07), bg.darkened(0.05))
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.add_child(tex_rect)
		if scene == "sunset" or scene == "sunset_plain":
			var bg_view := SceneBgScript.new()
			bg_view.show_sun = scene == "sunset"
			bg_view.set_anchors_preset(Control.PRESET_FULL_RECT)
			panel.add_child(bg_view)
	add_child(panel)
	return panel


func _make_margin(parent: Control, margin_x: int, margin_y: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", margin_x)
	margin.add_theme_constant_override("margin_right", margin_x)
	margin.add_theme_constant_override("margin_top", margin_y)
	margin.add_theme_constant_override("margin_bottom", margin_y)
	parent.add_child(margin)
	return margin


## Columna centrada de ancho fijo (ajustes, créditos, resultados).
func _make_center_box(panel: Control, width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(width, 0)
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)
	return vbox


## Botón "Volver al menú" de ancho razonable (no a todo lo ancho de la pantalla).
func _make_back_button() -> Button:
	var back := UI.make_button("Volver al menú", 26, UI.TEAL)
	back.custom_minimum_size = Vector2(380, 68)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: _show_panel(Screen.MENU))
	return back


# ------------------------------------------------------------------ UI: menús

func _build_ui() -> void:
	_build_menu()
	_build_howto()
	_build_settings()
	_build_credits()
	_build_game()
	_build_result()


func _build_menu() -> void:
	var panel := _make_panel(UI.CREAM, "sunset")
	panels[Screen.MENU] = panel
	# Ciclista que cruza el atardecer rodando por el horizonte (detrás del texto).
	menu_rider = BikeViewScript.new()
	menu_rider.custom_minimum_size = Vector2(250, 170)
	menu_rider.size = Vector2(250, 170)
	menu_rider.spin = true
	menu_rider.rider = true
	menu_rider.bike_color = Color(0.9, 0.2, 0.25, 1)
	panel.add_child(menu_rider)
	var margin := _make_margin(panel, 56, 36)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	margin.add_child(row)

	# Izquierda: título, eslogan, estadísticas y firma.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	row.add_child(left)
	left.add_child(UI.make_label("BiciTaller", 96, Color(1, 0.85, 0.2, 1), true, HORIZONTAL_ALIGNMENT_LEFT, 16))
	left.add_child(UI.make_label("Taller de bicis en Cuba", 32, Color.WHITE, true, HORIZONTAL_ALIGNMENT_LEFT, 8))
	left.add_child(UI.make_label("Repara bicis a contrarreloj. ¡Que no se te vaya ningún cliente!", 22, UI.MUTED, false, HORIZONTAL_ALIGNMENT_LEFT))
	menu_stats_label = UI.make_label("", 22, Color(0.35, 0.35, 0.35, 1), false, HORIZONTAL_ALIGNMENT_LEFT)
	left.add_child(menu_stats_label)
	UI.spacer(left, 10)
	# Firma en el menú, exactamente como pidió yopcubita. Amarillo claro con
	# sombra: va sobre la banda morada del suelo.
	left.add_child(UI.make_label(Data.SIGNATURE, 20, Color(1, 0.95, 0.55, 1), true, HORIZONTAL_ALIGNMENT_LEFT, 5))
	left.add_child(UI.make_label(Data.CREDIT_LINE, 16, Color(1, 0.92, 0.8, 1), true, HORIZONTAL_ALIGNMENT_LEFT))

	# Derecha: botones apilados, centrados en vertical.
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	right.add_theme_constant_override("separation", 14)
	row.add_child(right)
	UI.spacer(right)
	var play := UI.make_button("Jugar", 32)
	play.custom_minimum_size = Vector2(0, 80)
	play.pressed.connect(_on_play_pressed)
	right.add_child(play)
	var entries := [["Cómo jugar", Screen.HOWTO], ["Ajustes", Screen.SETTINGS], ["Créditos", Screen.CREDITS]]
	for entry in entries:
		var button := UI.make_button(entry[0], 26, UI.TEAL)
		button.pressed.connect(_show_panel.bind(entry[1]))
		right.add_child(button)
	UI.spacer(right)


func _build_howto() -> void:
	var panel := _make_panel(UI.CREAM, "sunset_plain")
	panels[Screen.HOWTO] = panel
	var margin := _make_margin(panel, 56, 32)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	vbox.add_child(UI.make_label("Cómo jugar", 48, Color(1, 0.85, 0.2, 1), true, HORIZONTAL_ALIGNMENT_CENTER, 12))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)
	var card_left := UI.make_card(0.9)
	card_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_left.add_child(UI.make_label(
		"1. Llega un cliente con su bici rota y te dice qué le duele.\n\n"
		+ "2. Elige la herramienta correcta:\n"
		+ "Bomba para la goma pinchada, Llave para la cadena salida, Destornillador para los frenos flojos.\n\n"
		+ "3. Completa el minijuego antes de que se acabe el tiempo.",
		27, UI.INK, false, HORIZONTAL_ALIGNMENT_LEFT))
	columns.add_child(card_left)
	var card_right := UI.make_card(0.9)
	card_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_right.add_child(UI.make_label(
		"4. Cada cliente tiene una barra de paciencia. Si se vacía, se va bravo y pierdes una vida. ¡Tienes %d vidas!\n\n" % MAX_LIVES
		+ "5. Cada arreglo paga %d monedas, más %d de propina si la paciencia quedó por encima de la mitad. Si arreglas %d seguidas sin fallar, ¡el pago se duplica (combo x2)!\n\n" % [BASE_PAY, TIP_PAY, COMBO_STREAK]
		+ "Al principio cada bici tiene 1 avería; después de %d bicis arregladas, llegan con 2." % TWO_FAULTS_AFTER,
		27, UI.INK, false, HORIZONTAL_ALIGNMENT_LEFT))
	columns.add_child(card_right)
	vbox.add_child(_make_back_button())


func _build_settings() -> void:
	var panel := _make_panel(UI.CREAM, "sunset_plain")
	panels[Screen.SETTINGS] = panel
	var vbox := _make_center_box(panel, 520)
	vbox.add_child(UI.make_label("Ajustes", 48, Color(1, 0.85, 0.2, 1), true, HORIZONTAL_ALIGNMENT_CENTER, 12))
	vib_button = UI.make_button("Vibración: ON", 26)
	vib_button.pressed.connect(_on_toggle_vibration)
	vbox.add_child(vib_button)
	sound_button = UI.make_button("Sonido: ON", 26)
	sound_button.pressed.connect(_on_toggle_sound)
	vbox.add_child(sound_button)
	music_button = UI.make_button("Música: ON", 26)
	music_button.pressed.connect(_on_toggle_music)
	vbox.add_child(music_button)
	var test_vib := UI.make_button("Probar vibración", 24)
	test_vib.pressed.connect(func() -> void: _vibrate(150))
	vbox.add_child(test_vib)
	vbox.add_child(_make_back_button())


func _build_credits() -> void:
	var panel := _make_panel(UI.CREAM, "sunset_plain")
	panels[Screen.CREDITS] = panel
	var vbox := _make_center_box(panel, 720)
	vbox.add_child(UI.make_label("Créditos", 48, Color(1, 0.85, 0.2, 1), true, HORIZONTAL_ALIGNMENT_CENTER, 12))
	# La firma es exactamente "Hecho por yopcubita". Blanco con sombra para que
	# se lea sobre el atardecer.
	vbox.add_child(UI.make_label(Data.SIGNATURE, 36, Color(1, 1, 1, 1), true))
	vbox.add_child(UI.make_label(Data.CREDIT_LINE, 24, Color(1, 0.92, 0.8, 1), true))
	vbox.add_child(UI.make_label("Un juego arcade hecho en Godot 4.3, sin internet, para jugar con los pulgares y con el corazón en el taller.", 20, Color(0.3, 0.25, 0.25, 1)))
	vbox.add_child(_make_back_button())


func _build_result() -> void:
	var panel := _make_panel(UI.CREAM, "sunset_plain")
	panels[Screen.RESULT] = panel
	var vbox := _make_center_box(panel, 720)
	vbox.add_child(UI.make_label("¡Fin de la jornada!", 48, Color(1, 0.85, 0.2, 1), true, HORIZONTAL_ALIGNMENT_CENTER, 12))
	var card := UI.make_card(0.9)
	vbox.add_child(card)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 6)
	card.add_child(stats)
	result_coins = UI.make_label("", 28, UI.INK)
	result_bikes = UI.make_label("", 28, UI.INK)
	result_streak = UI.make_label("", 28, UI.INK)
	result_best = UI.make_label("", 22, UI.MUTED)
	for label in [result_coins, result_bikes, result_streak, result_best]:
		stats.add_child(label)
	vbox.add_child(UI.make_label(Data.CREDIT_LINE, 20, Color(1, 0.95, 0.6, 1), true))
	vbox.add_child(UI.make_label(Data.SIGNATURE, 18, Color(1, 1, 1, 1), true))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	vbox.add_child(buttons)
	var retry := UI.make_button("Reintentar", 28)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(_on_play_pressed)
	buttons.add_child(retry)
	var menu := UI.make_button("Menú", 26, UI.TEAL)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(func() -> void: _show_panel(Screen.MENU))
	buttons.add_child(menu)


# ------------------------------------------------------------------ UI: juego

func _build_game() -> void:
	var panel := _make_panel(UI.SAND, "workshop")
	panels[Screen.GAME] = panel
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)
	root.add_child(_build_hud())

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(margin)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	margin.add_child(body)
	body.add_child(_build_client_column())
	body.add_child(_build_bike_column())
	body.add_child(_build_tools_column())


## Pastilla de color del HUD: [contenedor, etiqueta]. El icono es opcional.
func _make_pill(icon: Texture2D, text: String, bg: Color) -> Array:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UI.pill_style(bg))
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	pill.add_child(box)
	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(icon_rect)
	var label := UI.make_label(text, 24, Color.WHITE, false, HORIZONTAL_ALIGNMENT_CENTER, 6)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(label)
	return [pill, label]


func _build_hud() -> PanelContainer:
	var hud_panel := PanelContainer.new()
	var style := UI.card_style(0.94)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.set_border_width_all(0)
	style.border_width_bottom = 3
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	hud_panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	hud_panel.add_child(vbox)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	vbox.add_child(row)
	var day := _make_pill(null, "Día 1", Color(0.55, 0.36, 0.2, 1))
	row.add_child(day[0])
	hud_day = day[1]
	var coins := _make_pill(Icons.coin(), "Monedas: 0", Color(0.9, 0.62, 0.05, 1))
	row.add_child(coins[0])
	hud_coins = coins[1]
	var hearts := _make_pill(Icons.heart(), "Vidas: 3/3", Color(0.85, 0.2, 0.3, 1))
	row.add_child(hearts[0])
	hud_lives = hearts[1]
	var combo := _make_pill(null, "Racha: 0", Color(0.2, 0.5, 0.8, 1))
	row.add_child(combo[0])
	hud_combo = combo[1]
	hud_combo_pill = combo[0]
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	var quit := UI.make_button("Salir", 20, UI.GRAY)
	quit.custom_minimum_size = Vector2(120, 44)
	quit.pressed.connect(_on_quit_to_menu)
	row.add_child(quit)

	var patience_row := HBoxContainer.new()
	patience_row.add_theme_constant_override("separation", 14)
	vbox.add_child(patience_row)
	var patience_label := UI.make_label("Paciencia del cliente", 20, UI.BROWN, false, HORIZONTAL_ALIGNMENT_LEFT)
	patience_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	patience_row.add_child(patience_label)
	patience_bar = UI.make_patience_bar()
	patience_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	patience_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	patience_row.add_child(patience_bar)
	return hud_panel


func _build_client_column() -> Control:
	var card := UI.make_card(0.97)
	card.custom_minimum_size = Vector2(320, 0)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	client_view = ClientViewScript.new()
	client_view.custom_minimum_size = Vector2(0, 220)
	client_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(client_view)
	# Alturas mínimas fijas: si el texto cambia de 1 a 2 líneas, la bici no salta.
	client_label = UI.make_label("", 22, Color(0.15, 0.35, 0.6, 1))
	client_label.custom_minimum_size = Vector2(0, 58)
	client_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(client_label)
	symptom_label = UI.make_label("", 20, UI.INK)
	symptom_label.custom_minimum_size = Vector2(0, 96)
	symptom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(symptom_label)
	return card


func _build_bike_column() -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	bike_view = BikeViewScript.new()
	bike_view.custom_minimum_size = Vector2(300, 300)
	bike_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bike_view.resized.connect(func() -> void: call_deferred("_sync_workshop"))
	vbox.add_child(bike_view)
	var message_card := UI.make_card(0.92)
	message_card.custom_minimum_size = Vector2(0, 96)  # cabe en 2 líneas: la bici no salta
	message_label = UI.make_label("Elige la herramienta correcta.", 22, Color(0.6, 0.25, 0.1, 1))
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_card.add_child(message_label)
	vbox.add_child(message_card)
	return vbox


func _build_tools_column() -> Control:
	var card := UI.make_card(0.97)
	card.custom_minimum_size = Vector2(350, 0)
	var holder := VBoxContainer.new()
	card.add_child(holder)

	# Herramientas: tres botones grandes apilados (fáciles de tocar con el pulgar).
	tools_box = VBoxContainer.new()
	tools_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tools_box.add_theme_constant_override("separation", 12)
	holder.add_child(tools_box)
	tools_box.add_child(UI.make_label("Herramientas", 24, UI.BROWN))
	var tool_accents := {
		"bomba": Color(0.9, 0.45, 0.05, 1),
		"llave": Color(0.2, 0.45, 0.8, 1),
		"destornillador": Color(0.15, 0.6, 0.35, 1),
	}
	var tool_icons := {
		"bomba": Icons.pump(),
		"llave": Icons.wrench(),
		"destornillador": Icons.screwdriver(),
	}
	for tool_id in ["bomba", "llave", "destornillador"]:
		var button := UI.make_button(Data.TOOL_NAMES[tool_id], 26, tool_accents[tool_id])
		button.icon = tool_icons[tool_id]
		button.expand_icon = true
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 96)
		button.pressed.connect(_on_tool_pressed.bind(tool_id))
		tools_box.add_child(button)

	_build_minigame(holder)
	return card


func _build_minigame(parent: Control) -> void:
	mg_box = VBoxContainer.new()
	mg_box.visible = false
	mg_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mg_box.add_theme_constant_override("separation", 10)
	parent.add_child(mg_box)
	mg_title = UI.make_label("", 28, UI.RED)
	mg_box.add_child(mg_title)
	mg_info = UI.make_label("", 20, UI.INK)
	mg_info.custom_minimum_size = Vector2(0, 96)
	mg_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mg_box.add_child(mg_info)
	mg_bar = UI.make_bar(26, Color(0.1, 0.65, 0.55, 1))
	mg_box.add_child(mg_bar)
	zone_bar = ZoneBarScript.new()
	zone_bar.set_zone(BRAKE_ZONE_MIN, BRAKE_ZONE_MAX)
	mg_box.add_child(zone_bar)
	mg_time_bar = UI.make_bar(18, Color(0.95, 0.6, 0.1, 1))
	mg_time_bar.value = 100
	mg_box.add_child(mg_time_bar)
	# Bombear y frenar responden al DEDO ABAJO (no al soltar): más ágil.
	mg_action = UI.make_button("", 28, Color(0.9, 0.45, 0.05, 1))
	mg_action.set_meta("silent", true)
	mg_action.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mg_action.custom_minimum_size = Vector2(0, 110)
	mg_action.button_down.connect(_on_mg_action_down)
	mg_action.button_up.connect(_on_mg_action_up)
	mg_box.add_child(mg_action)
	mg_chain_box = GridContainer.new()
	mg_chain_box.columns = 2
	mg_chain_box.visible = false
	mg_chain_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mg_chain_box.add_theme_constant_override("h_separation", 10)
	mg_chain_box.add_theme_constant_override("v_separation", 10)
	mg_box.add_child(mg_chain_box)
	for i in 4:
		var button := UI.make_button("Eslabón %d" % (i + 1), 24)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.set_meta("silent", true)
		button.pressed.connect(_on_chain_pressed.bind(i + 1))
		mg_chain_box.add_child(button)
	var cancel := UI.make_button("Cancelar", 20, UI.GRAY)
	cancel.custom_minimum_size = Vector2(0, 52)
	cancel.pressed.connect(_on_mg_cancel)
	mg_box.add_child(cancel)


## Coloca el fondo del taller: la pared es la columna de la bici y el suelo
## empieza un poco por encima de donde apoyan las ruedas.
func _sync_workshop() -> void:
	if workshop_bg == null or bike_view == null or bike_view.size.x < 10.0:
		return
	var rect := Rect2(bike_view.global_position - global_position, bike_view.size)
	workshop_bg.set_layout(rect, rect.position.y + bike_view.ground_y() - 40.0)


# ------------------------------------------------------------------ Efectos

## Texto que sube y se desvanece (monedas, combo...). `at` está en coordenadas globales.
func _popup(text: String, color: Color, at: Vector2, font_size: int = 44) -> void:
	var label := UI.make_label(text, font_size, color, true, HORIZONTAL_ALIGNMENT_CENTER, 10)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	panels[Screen.GAME].add_child(label)
	label.reset_size()
	label.global_position = at - label.size * 0.5
	label.scale = Vector2(0.4, 0.4)
	label.pivot_offset = label.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position:y", label.global_position.y - 90.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.55)
	tween.chain().tween_callback(label.queue_free)


func _bike_center() -> Vector2:
	return bike_view.global_position + Vector2(bike_view.size.x * 0.5, bike_view.size.y * 0.45)


## Sacudida de la pantalla de juego (fallos, clientes que se van).
func _shake(strength: float = 10.0) -> void:
	var game_panel: Control = panels[Screen.GAME]
	var tween := create_tween()
	for i in 6:
		var amount := strength * (1.0 - float(i) / 6.0)
		tween.tween_property(game_panel, "position", Vector2(randf_range(-amount, amount), randf_range(-amount, amount) * 0.6), 0.04)
	tween.tween_property(game_panel, "position", Vector2.ZERO, 0.04)


# ------------------------------------------------------------------ Ajustes

func _update_settings_labels() -> void:
	vib_button.text = "Vibración: ON" if Save.vibracion else "Vibración: OFF"
	sound_button.text = "Sonido: ON" if Save.sonido else "Sonido: OFF"
	music_button.text = "Música: ON" if Save.musica else "Música: OFF"


func _on_toggle_vibration() -> void:
	Save.vibracion = not Save.vibracion
	Save.save_all()
	_update_settings_labels()
	if Save.vibracion:
		_vibrate(120)


func _on_toggle_sound() -> void:
	Save.sonido = not Save.sonido
	Save.save_all()
	_update_settings_labels()
	Sfx.play("coin")


func _on_toggle_music() -> void:
	Save.musica = not Save.musica
	Save.save_all()
	_update_settings_labels()
	Sfx.refresh_music()


func _vibrate(milliseconds: int = 80) -> void:
	if Save.vibracion:
		Input.vibrate_handheld(milliseconds)


# ------------------------------------------------------------------ Partida

@warning_ignore("integer_division")
func _day() -> int:
	return 1 + bikes_fixed / BIKES_PER_DAY


func _patience_rate() -> float:
	return 2.2 + 0.2 * float(_day())


func _on_play_pressed() -> void:
	lives = MAX_LIVES
	coins_run = 0
	bikes_fixed = 0
	streak = 0
	best_streak_run = 0
	waiting_next = false
	_hide_minigame()
	_show_panel(Screen.GAME)
	_next_client()


func _on_quit_to_menu() -> void:
	waiting_next = false
	_hide_minigame()
	_show_panel(Screen.MENU)


func _next_client() -> void:
	waiting_next = false
	var index := randi() % Data.CLIENTS.size()
	while Data.CLIENTS.size() > 1 and index == last_client_index:
		index = randi() % Data.CLIENTS.size()
	last_client_index = index
	current_client = Data.CLIENTS[index]
	var all_faults: Array = ["goma", "cadena", "frenos"]
	all_faults.shuffle()
	var count := 1 if bikes_fixed < TWO_FAULTS_AFTER else 2
	fault_ids = all_faults.slice(0, count)
	current_fault_index = 0
	patience = 100.0
	_update_game_ui()
	client_view.pop()
	bike_view.enter()
	Sfx.play("bell")
	message_label.text = "Elige la herramienta correcta."


func _current_fault() -> Dictionary:
	return Data.FAULTS[fault_ids[current_fault_index]]


func _mood_from_patience() -> int:
	if patience >= 50.0:
		return 0
	if patience >= 25.0:
		return 1
	return 2


func _update_game_ui() -> void:
	var fault: Dictionary = _current_fault()
	hud_day.text = "Día %d" % _day()
	hud_coins.text = "Monedas: %d" % coins_run
	hud_lives.text = "Vidas: %d/%d" % [lives, MAX_LIVES]
	hud_combo.text = "Racha: %d ¡x2!" % streak if streak >= COMBO_STREAK else "Racha: %d" % streak
	hud_combo_pill.add_theme_stylebox_override("panel", UI.pill_style(Color(1, 0.5, 0.1, 1) if streak >= COMBO_STREAK else Color(0.2, 0.5, 0.8, 1)))
	patience_bar.value = patience
	client_label.text = "%s — %s" % [current_client["nombre"], current_client["bici"]]
	symptom_label.text = "%s\nAvería: %s" % [fault["sintoma"], fault["nombre"]]
	_last_mood = _mood_from_patience()
	client_view.set_client(current_client, _last_mood)
	bike_view.set_bike(current_client["color"], fault["id"])


func _process(delta: float) -> void:
	_time += delta
	if screen == Screen.MENU:
		_menu_time += delta
		var travel := size.x + 500.0
		menu_rider.position = Vector2(fposmod(_menu_time * 120.0, travel) - 280.0, size.y * 0.86 + 12.0 - (menu_rider.size.y - 22.0))
	if screen != Screen.GAME:
		return
	# Con poca paciencia la barra parpadea en rojo.
	if patience < 30.0 and not waiting_next and not mg_active:
		patience_bar.modulate = Color.WHITE.lerp(Color(1, 0.45, 0.45), 0.5 + 0.5 * sin(_time * 12.0))
	else:
		patience_bar.modulate = Color.WHITE
	if waiting_next:
		waiting_timer -= delta
		if waiting_timer <= 0.0:
			_next_client()
		return
	if mg_active:
		_process_minigame(delta)
		return
	patience -= _patience_rate() * delta
	patience_bar.value = patience
	var mood_now := _mood_from_patience()
	if mood_now != _last_mood:
		_last_mood = mood_now
		client_view.set_mood(mood_now)
	if patience <= 0.0:
		_client_leaves()


func _client_leaves() -> void:
	lives -= 1
	streak = 0
	_vibrate(200)
	_shake(16.0)
	Sfx.play("leave")
	if lives <= 0:
		_end_day()
		return
	_next_client()
	var remaining := "Te quedan %d vidas." % lives if lives != 1 else "Te queda 1 vida."
	message_label.text = "¡El cliente se fue bravo! %s" % remaining


func _end_day() -> void:
	_hide_minigame()
	Sfx.play("gameover")
	Save.register_day(coins_run, bikes_fixed, best_streak_run)
	result_coins.text = "Monedas ganadas: %d" % coins_run
	result_bikes.text = "Bicis arregladas: %d" % bikes_fixed
	result_streak.text = "Mejor racha: %d" % best_streak_run
	result_best.text = "Récord: %d bicis en una jornada  •  Monedas totales: %d" % [Save.best_bikes, Save.total_coins]
	_show_panel(Screen.RESULT)


# ------------------------------------------------------------------ Herramientas

func _on_tool_pressed(tool_id: String) -> void:
	if screen != Screen.GAME or mg_active or waiting_next:
		return
	var fault: Dictionary = _current_fault()
	if tool_id == fault["herramienta"]:
		_start_minigame()
		return
	streak = 0
	patience -= WRONG_TOOL_PATIENCE
	_vibrate(150)
	_shake(9.0)
	Sfx.play("wrong")
	_popup("¡No!", Color(1, 0.4, 0.35, 1), _bike_center(), 40)
	if patience <= 0.0:
		_client_leaves()
		return
	_update_game_ui()
	message_label.text = "¡Esa no es la herramienta! La paciencia baja..."


# ------------------------------------------------------------------ Minijuegos

func _set_minigame_visible(show: bool) -> void:
	mg_box.visible = show
	tools_box.visible = not show


## Cierra el minijuego sin dar premio ni castigo (se usa al cancelar, salir y terminar).
func _hide_minigame() -> void:
	mg_active = false
	mg_holding = false
	_set_minigame_visible(false)


func _start_minigame() -> void:
	var fault: Dictionary = _current_fault()
	mg_type = fault["id"]
	mg_active = true
	mg_progress = 0.0
	mg_chain_step = 0
	mg_needle = 0.0
	mg_needle_dir = 1.0
	mg_holding = false
	mg_bar.value = 0
	zone_bar.value = 0.0
	mg_title.text = fault["nombre"]
	mg_info.text = fault["pista"]
	mg_chain_box.visible = mg_type == "cadena"
	mg_action.visible = mg_type != "cadena"
	mg_bar.visible = mg_type != "frenos"
	zone_bar.visible = mg_type == "frenos"
	match mg_type:
		"goma":
			mg_time_max = TIME_GOMA
			mg_action.text = "¡BOMBEAR!\n(toca muchas veces)"
		"cadena":
			mg_time_max = TIME_CADENA
			mg_info.text = "Toca los eslabones en orden: 1, 2, 3, 4."
		"frenos":
			mg_time_max = TIME_FRENOS
			mg_action.text = "MANTENER PULSADO"
			mg_info.text = "Mantén pulsado para mover la aguja y suelta en la zona verde (%d a %d)." \
				% [int(BRAKE_ZONE_MIN), int(BRAKE_ZONE_MAX)]
	mg_time_left = mg_time_max
	mg_time_bar.value = 100
	_set_minigame_visible(true)


func _process_minigame(delta: float) -> void:
	mg_time_left -= delta
	mg_time_bar.value = clampf(mg_time_left / mg_time_max * 100.0, 0.0, 100.0)
	if mg_time_left <= 0.0:
		_minigame_fail("¡Se acabó el tiempo!")
		return
	if mg_type == "frenos" and mg_holding:
		mg_needle += delta * NEEDLE_SPEED * mg_needle_dir
		if mg_needle >= 100.0:
			mg_needle = 100.0
			mg_needle_dir = -1.0
		elif mg_needle <= 0.0:
			mg_needle = 0.0
			mg_needle_dir = 1.0
		zone_bar.value = mg_needle
		# Tic-tac que sube de tono dentro de la zona verde: se "oye" el punto justo.
		_tick_time -= delta
		if _tick_time <= 0.0:
			var in_zone := mg_needle >= BRAKE_ZONE_MIN and mg_needle <= BRAKE_ZONE_MAX
			Sfx.play("tick", 1.5 if in_zone else 0.8, -4.0)
			_tick_time = 0.11
		mg_info.text = "Aguja: %d — suelta entre %d y %d." % [int(mg_needle), int(BRAKE_ZONE_MIN), int(BRAKE_ZONE_MAX)]


func _on_mg_action_down() -> void:
	if not mg_active:
		return
	if mg_type == "goma":
		mg_progress += PUMP_PER_TAP
		Sfx.play("pump", 0.85 + minf(mg_progress, 100.0) / 100.0 * 0.55)   # sube de tono al llenarse
		mg_bar.value = mg_progress
		mg_info.text = "Aire: %d%% — ¡sigue bombeando!" % int(minf(mg_progress, 100.0))
		if mg_progress >= 100.0:
			_minigame_success()
	elif mg_type == "frenos":
		mg_holding = true
		_tick_time = 0.0


func _on_mg_action_up() -> void:
	if not mg_active or mg_type != "frenos" or not mg_holding:
		return
	mg_holding = false
	if mg_needle >= BRAKE_ZONE_MIN and mg_needle <= BRAKE_ZONE_MAX:
		Sfx.play("squeak")
		_minigame_success()
	else:
		_minigame_fail("La aguja no quedó en la zona verde (%d-%d)." % [int(BRAKE_ZONE_MIN), int(BRAKE_ZONE_MAX)])


func _on_chain_pressed(number: int) -> void:
	if not mg_active or mg_type != "cadena":
		return
	if number == mg_chain_step + 1:
		mg_chain_step += 1
		Sfx.play("chain", 0.9 + 0.12 * float(mg_chain_step))
		mg_progress = float(mg_chain_step) * 25.0
		mg_bar.value = mg_progress
		if mg_chain_step >= 4:
			_minigame_success()
		else:
			mg_info.text = "¡Bien! Eslabón %d puesto. Falta el %d." % [mg_chain_step, mg_chain_step + 1]
	else:
		Sfx.play("wrong", 1.0, -4.0)
		mg_chain_step = 0
		mg_progress = 0.0
		mg_bar.value = 0
		mg_info.text = "¡Ese eslabón no va ahí! Empieza de nuevo: 1, 2, 3, 4."


func _on_mg_cancel() -> void:
	if not mg_active:
		return
	_hide_minigame()
	message_label.text = "Minijuego cancelado. Elige otra vez la herramienta."


func _minigame_success() -> void:
	_hide_minigame()
	bike_view.celebrate()
	streak += 1
	best_streak_run = maxi(best_streak_run, streak)
	var pay := BASE_PAY
	if patience > TIP_PATIENCE_MIN:
		pay += TIP_PAY
	var doubled := streak >= COMBO_STREAK
	if doubled:
		pay *= 2
	coins_run += pay
	_vibrate(80)
	var combo_text := " ¡COMBO x2!" if doubled else ""
	Sfx.play("success")
	Sfx.play("coin")
	if doubled:
		Sfx.play("combo", 1.0, -3.0)
	_popup("+%d" % pay, Color(1, 0.85, 0.2, 1), _bike_center())
	if doubled:
		_popup("¡COMBO x2!", Color(1, 0.55, 0.15, 1), _bike_center() + Vector2(0, 56), 34)
	if current_fault_index + 1 < fault_ids.size():
		current_fault_index += 1
		_update_game_ui()
		message_label.text = "¡Reparado! +%d monedas.%s Falta otra avería en esta bici." % [pay, combo_text]
	else:
		bikes_fixed += 1
		_update_game_ui()
		bike_view.set_bike(current_client["color"], "")  # ya no hay avería que marcar
		message_label.text = "¡Bici lista! Cliente contento. +%d monedas.%s" % [pay, combo_text]
		waiting_next = true
		waiting_timer = NEXT_CLIENT_DELAY


func _minigame_fail(reason: String) -> void:
	_hide_minigame()
	streak = 0
	patience -= FAIL_PATIENCE
	_vibrate(150)
	_shake(9.0)
	Sfx.play("fail")
	_popup("¡Falló!", Color(1, 0.4, 0.35, 1), _bike_center(), 40)
	if patience <= 0.0:
		_client_leaves()
		return
	_update_game_ui()
	message_label.text = "%s La paciencia baja..." % reason

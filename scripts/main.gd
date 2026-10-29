extends Node2D

const FighterScene = preload("res://scripts/fighter.gd")
const AeroHealthBarScript = preload("res://scripts/aero_health_bar.gd")
const MascotEmblemScript = preload("res://scripts/mascot_emblem.gd")

const CHARACTERS := [
	{"id": "tux", "name": "Tux", "description": "Linux penguin • balanced", "tag": "THE ORIGINAL", "symbol": "🐧", "color": Color("#79d7ff")},
	{"id": "gnu", "name": "GNU", "description": "GNU wildebeest • heavy", "tag": "HEAVY HITTER", "symbol": "♞", "color": Color("#d7c6a1")},
	{"id": "beastie", "name": "Beastie", "description": "BSD daemon • aggressive", "tag": "RUSHDOWN", "symbol": "🔥", "color": Color("#ff657c")},
	{"id": "puffy", "name": "Puffy", "description": "OpenBSD pufferfish • quick", "tag": "QUICK & TRICKY", "symbol": "✦", "color": Color("#ffd84d")}
]

const SCREEN_SIZE := Vector2(1280, 720)
const PLAYER_ONE_START := Vector2(360, 560)
const PLAYER_TWO_START := Vector2(920, 560)
const ROUND_DELAY := 2.0
const INTRO_DELAY := 0.75
const KNOCKBACK := 180.0
const HIT_VERTICAL_REACH := 100.0

const BACKGROUND := Color("#080e1c")
const FLOOR_COLOR := Color("#101b2d")
const GRID_COLOR := Color("#223753")
const ACCENT_BLUE := Color("#7dd3fc")
const ACCENT_GREEN := Color("#a7f3d0")
const PUFFY_YELLOW := Color("#ffd43b")

var p1: Fighter
var p2: Fighter
var p1_bar: Control
var p2_bar: Control
var status_label: Label
var round_label: Label
var controls_label: Label
var selection_layer: CanvasLayer
var selection_label: Label
var selection_buttons: Array[Button] = []
var selected_index := 0
var selecting := true
var round_number := 1
var p1_rounds := 0
var p2_rounds := 0
var round_locked := false
var reset_timer := 0.0
var arena_camera: Camera2D
var shake_timer := 0.0
var shake_strength := 0.0
var hit_sparks: Array[Dictionary] = []
var boss_mode := false
var active_boss_id := ""
var pause_menu_layer: CanvasLayer
var game_ui_layer: CanvasLayer
var game_paused := false


func _ready() -> void:
	# The controller stays alive to receive the resume key while the scene tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_create_selection_screen()
	queue_redraw()


# -------------------------------------------------------------------
# Character selection
# -------------------------------------------------------------------

func _create_selection_screen() -> void:
	selection_layer = CanvasLayer.new()
	add_child(selection_layer)

	var background := ColorRect.new()
	background.color = Color("#080d18")
	background.size = SCREEN_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_layer.add_child(background)

	# Layered cards and decorative framing make the select screen feel intentional.
	var top_line := ColorRect.new()
	top_line.position = Vector2(80, 44)
	top_line.size = Vector2(1120, 2)
	top_line.color = Color("#284866")
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_layer.add_child(top_line)

	var eyebrow := _make_label("OPEN-SOURCE FIGHTING • BUILD 0.2", Vector2(0, 57), Vector2(1280, 24), 13, Color("#7dd3fc"))
	eyebrow.add_theme_color_override("font_color", Color("#7dd3fc"))
	selection_layer.add_child(eyebrow)

	var title := _make_label("TUX COMBAT", Vector2(0, 82), Vector2(1280, 70), 54, Color("#f2f8ff"))
	title.add_theme_color_override("font_shadow_color", Color(0.2, 0.7, 1.0, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	selection_layer.add_child(title)

	var subtitle := _make_label("CHOOSE YOUR CHAMPION", Vector2(0, 151), Vector2(1280, 28), 17, Color("#9bb6d3"))
	selection_layer.add_child(subtitle)

	var accent := ColorRect.new()
	accent.position = Vector2(565, 192)
	accent.size = Vector2(150, 3)
	accent.color = ACCENT_BLUE
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_layer.add_child(accent)

	for i in range(CHARACTERS.size()):
		var character: Dictionary = CHARACTERS[i]
		var card := Panel.new()
		card.position = Vector2(68 + i * 292, 222)
		card.size = Vector2(264, 284)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color("#111d30")
		panel_style.border_color = character["color"].darkened(0.28)
		panel_style.set_border_width_all(1)
		panel_style.set_corner_radius_all(12)
		panel_style.shadow_color = Color(0, 0, 0, 0.28)
		panel_style.shadow_size = 10
		card.add_theme_stylebox_override("panel", panel_style)
		selection_layer.add_child(card)

		var stripe := ColorRect.new()
		stripe.position = Vector2(0, 0)
		stripe.size = Vector2(264, 5)
		stripe.color = character["color"]
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(stripe)

		var emblem := MascotEmblemScript.new() as Node2D
		emblem.character_id = character["id"]
		emblem.position = Vector2(132, 69)
		emblem.scale = Vector2(1.28, 1.28)
		card.add_child(emblem)

		var name_label := _make_label(character["name"].to_upper(), Vector2(12, 113), Vector2(240, 34), 25, Color("#f4f8ff"))
		card.add_child(name_label)

		var tag_label := _make_label(character["tag"], Vector2(12, 150), Vector2(240, 22), 12, character["color"])
		card.add_child(tag_label)

		var description := _make_label(character["description"], Vector2(12, 181), Vector2(240, 38), 14, Color("#a9bbd1"))
		card.add_child(description)

		var button := Button.new()
		button.text = "SELECT FIGHTER"
		button.position = Vector2(15, 231)
		button.size = Vector2(234, 38)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", Color("#f5fbff"))
		button.add_theme_color_override("font_hover_color", Color("#ffffff"))
		button.add_theme_color_override("font_pressed_color", Color("#dff6ff"))
		button.add_theme_stylebox_override("normal", _button_style(Color("#1b3049"), character["color"].darkened(0.2)))
		button.add_theme_stylebox_override("hover", _button_style(Color("#294967"), character["color"]))
		button.add_theme_stylebox_override("pressed", _button_style(Color("#102236"), character["color"]))
		button.add_theme_stylebox_override("focus", _button_style(Color("#1b3049"), character["color"]))
		button.tooltip_text = "Choose %s and enter the arena" % character["name"]
		button.pressed.connect(_select_character.bind(i))
		card.add_child(button)
		selection_buttons.append(button)

	selection_label = _make_label("", Vector2(0, 535), Vector2(1280, 32), 17, Color("#e6f5ff"))
	selection_layer.add_child(selection_label)

	var controls := _make_label("← / →  NAVIGATE     ENTER  FIGHT     OR CLICK A FIGHTER", Vector2(0, 582), Vector2(1280, 26), 13, Color("#718ca9"))
	selection_layer.add_child(controls)

	var footer := _make_label("LINUX • UNIX • BSD • OPEN SOURCE", Vector2(0, 650), Vector2(1280, 24), 12, Color("#405b78"))
	selection_layer.add_child(footer)

	_update_selection_visuals()


func _make_label(text_value: String, pos: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _update_selection_visuals() -> void:
	for i in range(selection_buttons.size()):
		var button := selection_buttons[i]
		var character: Dictionary = CHARACTERS[i]
		button.text = "✓ FIGHTER SELECTED" if i == selected_index else "SELECT FIGHTER"
		if i == selected_index:
			button.add_theme_stylebox_override("normal", _button_style(Color("#24445f"), character["color"]))
			button.add_theme_color_override("font_color", character["color"])
		else:
			button.add_theme_stylebox_override("normal", _button_style(Color("#1b3049"), character["color"].darkened(0.2)))
			button.add_theme_color_override("font_color", Color("#f5fbff"))

	if is_instance_valid(selection_label):
		selection_label.text = "READY TO FIGHT  •  %s" % CHARACTERS[selected_index]["name"].to_upper()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not selecting and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P):
			_toggle_pause()
			get_viewport().set_input_as_handled()
			return
		if not selecting:
			return
		match event.keycode:
			KEY_LEFT:
				selected_index = (selected_index - 1 + CHARACTERS.size()) % CHARACTERS.size()
				_update_selection_visuals()
			KEY_RIGHT:
				selected_index = (selected_index + 1) % CHARACTERS.size()
				_update_selection_visuals()
			KEY_ENTER, KEY_KP_ENTER:
				_start_game(selected_index)




# -------------------------------------------------------------------
# Pause menu
# -------------------------------------------------------------------

func _toggle_pause() -> void:
	if selecting:
		return
	if game_paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game() -> void:
	if selecting or game_paused:
		return
	game_paused = true
	get_tree().paused = true
	_create_pause_menu()


func _resume_game() -> void:
	game_paused = false
	get_tree().paused = false
	if is_instance_valid(pause_menu_layer):
		pause_menu_layer.queue_free()
	pause_menu_layer = null


func _restart_round_from_pause() -> void:
	_resume_game()
	_reset_round()


func _create_pause_menu() -> void:
	if is_instance_valid(pause_menu_layer):
		pause_menu_layer.queue_free()
	pause_menu_layer = CanvasLayer.new()
	pause_menu_layer.name = "PauseMenuLayer"
	pause_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu_layer.layer = 20
	add_child(pause_menu_layer)

	var dimmer := ColorRect.new()
	dimmer.position = Vector2.ZERO
	dimmer.size = SCREEN_SIZE
	dimmer.color = Color(0.015, 0.025, 0.05, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_menu_layer.add_child(dimmer)

	var panel := Panel.new()
	panel.position = Vector2(420, 155)
	panel.size = Vector2(440, 410)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#101d31")
	panel_style.border_color = Color("#62d9ff")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	pause_menu_layer.add_child(panel)

	var heading := _make_label("GAME PAUSED", Vector2(440, 185), Vector2(400, 62), 34, Color("#f2f8ff"))
	pause_menu_layer.add_child(heading)
	var subtitle := _make_label("THE ARENA IS FROZEN", Vector2(440, 239), Vector2(400, 28), 14, Color("#7dd3fc"))
	pause_menu_layer.add_child(subtitle)

	var resume_button := _pause_menu_button("RESUME  [ESC / P]", Vector2(490, 292), Color("#1d4960"), Color("#70e4ff"))
	resume_button.pressed.connect(_resume_game)
	pause_menu_layer.add_child(resume_button)

	var restart_button := _pause_menu_button("RESTART ROUND", Vector2(490, 354), Color("#263753"), Color("#9ccaff"))
	restart_button.pressed.connect(_restart_round_from_pause)
	pause_menu_layer.add_child(restart_button)

	var hint := _make_label("ESC or P resumes the fight", Vector2(440, 440), Vector2(400, 30), 13, Color("#91a9c5"))
	pause_menu_layer.add_child(hint)


func _pause_menu_button(button_text: String, pos: Vector2, fill: Color, border: Color) -> Button:
	var button := Button.new()
	button.text = button_text
	button.position = pos
	button.size = Vector2(300, 48)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#f5fbff"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_stylebox_override("normal", _button_style(fill, border))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.14), border.lightened(0.15)))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.18), border))
	button.add_theme_stylebox_override("focus", _button_style(fill, border.lightened(0.2)))
	return button


func _select_character(index: int) -> void:
	if index < 0 or index >= CHARACTERS.size():
		return
	selected_index = index
	_update_selection_visuals()
	_start_game(index)


func _start_game(player_choice: int) -> void:
	if not selecting or player_choice < 0 or player_choice >= CHARACTERS.size():
		return
	selecting = false
	if is_instance_valid(selection_layer):
		selection_layer.queue_free()
	_create_ui()
	_create_fighters(player_choice)
	queue_redraw()


# -------------------------------------------------------------------
# Fighters and HUD
# -------------------------------------------------------------------

func _create_fighters(player_choice: int) -> void:
	var player_data: Dictionary = CHARACTERS[player_choice]
	var cpu_choice := (player_choice + randi_range(1, CHARACTERS.size() - 1)) % CHARACTERS.size()
	var cpu_data: Dictionary = CHARACTERS[cpu_choice]

	p1 = FighterScene.new() as Fighter
	p1.process_mode = Node.PROCESS_MODE_PAUSABLE
	p1.add_to_group("fighters")
	add_child(p1)
	p1.setup(player_data["name"], 1, false, player_data["id"])
	p1.strike.connect(_on_strike)

	p2 = FighterScene.new() as Fighter
	p2.process_mode = Node.PROCESS_MODE_PAUSABLE
	p2.add_to_group("fighters")
	add_child(p2)
	p2.strike.connect(_on_strike)
	_setup_regular_opponent(cpu_data)
	p1_bar.set_fighter_label(p1.fighter_name)
	_reset_round()


const DISTRO_BOSSES := [
	{"id": "boss_arch", "name": "Arch Warden", "color": Color("#1793d1"), "tagline": "ROLLING RELEASE"},
	{"id": "boss_ubuntu", "name": "Ubuntu Overlord", "color": Color("#e95420"), "tagline": "CIRCLE OF FRIENDS"},
	{"id": "boss_fedora", "name": "Fedora Sentinel", "color": Color("#51a2da"), "tagline": "INNOVATION CORE"},
	{"id": "boss_debian", "name": "Debian Maelstrom", "color": Color("#d70a53"), "tagline": "UNIVERSAL CHAOS"},
	{"id": "boss_nix", "name": "Nix Frostbyte", "color": Color("#7ebae4"), "tagline": "PURE REPRODUCIBILITY"},
	{"id": "boss_kali", "name": "Kali Nightfall", "color": Color("#557c94"), "tagline": "OFFENSIVE EDGE"},
	{"id": "boss_mint", "name": "Mint Verdant", "color": Color("#87cf3e"), "tagline": "FRESH AND STABLE"},
	{"id": "boss_gentoo", "name": "Gentoo Overclock", "color": Color("#b59af0"), "tagline": "COMPILE YOUR DESTINY"}
]


func _setup_regular_opponent(data: Dictionary) -> void:
	boss_mode = false
	active_boss_id = ""
	p2.setup(data["name"], 2, true, data["id"])
	p2_bar.setup("CPU", 2, p2.max_health)
	p2_bar.set_fighter_label(p2.fighter_name)
	controls_label.text = "P1  A/D MOVE  •  W JUMP  •  S CROUCH  •  J PUNCH  •  K KICK     |     CPU: %s" % p2.fighter_name.to_upper()


func _setup_boss_opponent() -> void:
	var boss: Dictionary = DISTRO_BOSSES[randi_range(0, DISTRO_BOSSES.size() - 1)]
	boss_mode = true
	active_boss_id = boss["id"]
	p2.setup(boss["name"], 2, true, boss["id"])
	p2_bar.setup("DISTRO BOSS", 2, p2.max_health)
	p2_bar.set_fighter_label(p2.fighter_name)
	controls_label.text = "BOSS CHALLENGE  •  A/D MOVE  •  W JUMP  •  S CROUCH  •  J PUNCH  •  K KICK"
	status_label.text = "%s  •  %s" % [p2.fighter_name.to_upper(), boss["tagline"]]


func _create_ui() -> void:
	arena_camera = Camera2D.new()
	arena_camera.position = Vector2(640, 360)
	arena_camera.position_smoothing_enabled = false
	add_child(arena_camera)
	arena_camera.make_current()

	game_ui_layer = CanvasLayer.new()
	add_child(game_ui_layer)
	var layer := game_ui_layer

	var title_panel := Panel.new()
	title_panel.position = Vector2(510, 5)
	title_panel.size = Vector2(260, 37)
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color("#152840")
	title_style.border_color = Color("#41698a")
	title_style.set_border_width_all(1)
	title_style.set_corner_radius_all(8)
	title_panel.add_theme_stylebox_override("panel", title_style)
	layer.add_child(title_panel)

	var title := _make_label("T U X   C O M B A T", Vector2(510, 5), Vector2(260, 37), 18, Color("#e6f7ff"))
	layer.add_child(title)

	p1_bar = AeroHealthBarScript.new()
	p1_bar.position = Vector2(52, 48)
	p1_bar.size = Vector2(500, 40)
	p1_bar.setup("PLAYER 1", 1, 100)
	layer.add_child(p1_bar)

	p2_bar = AeroHealthBarScript.new()
	p2_bar.position = Vector2(728, 48)
	p2_bar.size = Vector2(500, 40)
	p2_bar.setup("CPU", 2, 100)
	layer.add_child(p2_bar)

	round_label = _make_label("", Vector2(440, 91), Vector2(400, 28), 18, ACCENT_BLUE)
	layer.add_child(round_label)

	status_label = _make_label("", Vector2(250, 566), Vector2(780, 62), 28, Color("#f4fbff"))
	layer.add_child(status_label)

	var status_panel := Panel.new()
	status_panel.position = Vector2(320, 578)
	status_panel.size = Vector2(640, 42)
	var status_style := StyleBoxFlat.new()
	status_style.bg_color = Color(0.02, 0.06, 0.12, 0.76)
	status_style.border_color = Color(0.25, 0.55, 0.78, 0.7)
	status_style.set_border_width_all(1)
	status_style.set_corner_radius_all(10)
	status_panel.add_theme_stylebox_override("panel", status_style)
	status_panel.z_index = -1
	layer.add_child(status_panel)

	controls_label = _make_label("ESC / P  PAUSE", Vector2(40, 670), Vector2(1200, 26), 12, Color("#91a9c5"))
	layer.add_child(controls_label)


# -------------------------------------------------------------------
# Game loop and rounds
# -------------------------------------------------------------------

func _process(delta: float) -> void:
	if game_paused:
		return
	if shake_timer > 0.0:
		shake_timer = maxf(0.0, shake_timer - delta)
		if is_instance_valid(arena_camera):
			var strength := shake_strength * (shake_timer / 0.18)
			arena_camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		if shake_timer <= 0.0 and is_instance_valid(arena_camera):
			arena_camera.offset = Vector2.ZERO
	var had_sparks := not hit_sparks.is_empty()
	for i in range(hit_sparks.size() - 1, -1, -1):
		var spark: Dictionary = hit_sparks[i]
		spark["life"] = float(spark["life"]) - delta
		spark["position"] = spark["position"] + spark["velocity"] * delta
		spark["velocity"] = spark["velocity"] * 0.90 + Vector2(0, 115) * delta
		if float(spark["life"]) <= 0.0:
			hit_sparks.remove_at(i)
		else:
			hit_sparks[i] = spark
	if had_sparks:
		queue_redraw()

	if selecting or not is_instance_valid(p1) or not is_instance_valid(p2):
		return

	p1_bar.set_health(p1.health)
	p2_bar.set_health(p2.health)
	round_label.text = "ROUND %d     •     SCORE  %d  —  %d" % [round_number, p1_rounds, p2_rounds]

	if round_locked:
		reset_timer -= delta
		if reset_timer <= 0.0:
			if p1_rounds >= 2 or p2_rounds >= 2:
				var player_won_match := p1_rounds >= 2
				if player_won_match and not boss_mode:
					_setup_boss_opponent()
				elif boss_mode:
					# Boss defeated or boss won: return to the standard CPU roster.
					var regular_choice: Dictionary = CHARACTERS[randi_range(0, CHARACTERS.size() - 1)]
					_setup_regular_opponent(regular_choice)
				round_number = 1
				p1_rounds = 0
				p2_rounds = 0
			else:
				round_number += 1
			_reset_round()
		queue_redraw()
		return

	if p1.health <= 0 or p2.health <= 0:
		_end_round()
	queue_redraw()


func _on_strike(attacker: Fighter, damage: int, reach: float, attack_type: String) -> void:
	if round_locked or not is_instance_valid(attacker):
		return
	if attacker != p1 and attacker != p2:
		return
	if damage <= 0 or reach <= 0.0 or (attack_type != "punch" and attack_type != "kick"):
		return

	var target: Fighter = p2 if attacker == p1 else p1
	if not is_instance_valid(target) or target.health <= 0:
		return

	var target_offset := target.position.x - attacker.position.x
	if target_offset * attacker.facing < -8.0:
		return

	# Real attack/hurt rectangles: punches target the upper body, kicks target the lower body.
	# The target hurtbox follows jumps, so attacks can whiff over or under a moving opponent.
	var attack_box: Rect2
	if attack_type == "punch":
		attack_box = Rect2(
			attacker.position + Vector2(attacker.facing * 58.0 - 41.0, -91.0),
			Vector2(82.0, 48.0)
		)
	else:
		attack_box = Rect2(
			attacker.position + Vector2(attacker.facing * 70.0 - 55.0, -49.0),
			Vector2(110.0, 46.0)
		)
	var hurt_box := Rect2(target.position + Vector2(-39.0, -112.0), Vector2(78.0, 118.0))
	if not attack_box.intersects(hurt_box):
		return
	# Reach remains a safety cap, while the rectangles decide whether the strike actually connects.
	if absf(target_offset) > reach + 18.0:
		return

	var direction := signf(target_offset)
	if direction == 0.0:
		direction = attacker.facing
	target.take_damage(damage, direction * (KNOCKBACK * (1.3 if attack_type == "kick" else 1.0)))
	var impact_position := target.global_position + Vector2(-direction * 10.0, -65.0 if attack_type == "punch" else -35.0)
	_spawn_hit_spark(impact_position, attack_type, attacker)
	shake_timer = 0.22 if attack_type == "kick" else 0.14
	shake_strength = 9.0 if attack_type == "kick" else 5.0
	if is_instance_valid(arena_camera):
		arena_camera.offset = Vector2.ZERO
	queue_redraw()


func _spawn_hit_spark(hit_position: Vector2, attack_type: String, attacker: Fighter) -> void:
	var spark_color := Color("#ffd43b") if attack_type == "kick" else Color("#7dd3fc")
	if attacker.character_id == "beastie":
		spark_color = Color("#ff657c")
	elif attacker.character_id == "puffy":
		spark_color = Color("#fff0a0")
	elif attacker.character_id == "gnu":
		spark_color = Color("#e8d9c5")
	elif attacker.character_id == "boss_arch":
		spark_color = Color("#1793d1")
	elif attacker.character_id == "boss_ubuntu":
		spark_color = Color("#e95420")
	elif attacker.character_id == "boss_fedora":
		spark_color = Color("#51a2da")
	elif attacker.character_id == "boss_debian":
		spark_color = Color("#d70a53")
	hit_sparks.append({
		"position": hit_position,
		"velocity": Vector2.ZERO,
		"life": 0.28 if attack_type == "kick" else 0.20,
		"color": spark_color,
		"seed": randf() * TAU,
		"kind": attack_type
	})
	for i in range(12 if attack_type == "kick" else 8):
		var angle := TAU * float(i) / float(12 if attack_type == "kick" else 8) + randf_range(-0.18, 0.18)
		var speed := randf_range(120.0, 310.0) if attack_type == "kick" else randf_range(90.0, 240.0)
		hit_sparks.append({
			"position": hit_position,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.16, 0.30),
			"color": spark_color,
			"seed": randf() * TAU,
			"kind": attack_type
		})


func _end_round() -> void:
	if round_locked:
		return
	round_locked = true
	reset_timer = ROUND_DELAY
	var winner: Fighter = p1 if p1.health > 0 else p2
	if winner == p1:
		p1_rounds += 1
	else:
		p2_rounds += 1
	if p1_rounds >= 2 or p2_rounds >= 2:
		if p1_rounds >= 2 and not boss_mode:
			status_label.text = "%s WINS! A DISTRO BOSS HAS CHALLENGED YOU..." % winner.fighter_name.to_upper()
		elif boss_mode and p1_rounds >= 2:
			status_label.text = "%s DEFEATED THE DISTRO BOSS!" % winner.fighter_name.to_upper()
		else:
			status_label.text = "%s WINS THE MATCH!" % winner.fighter_name.to_upper()
	else:
		status_label.text = "%s TAKES THE ROUND!" % winner.fighter_name.to_upper()


func _reset_round() -> void:
	if not is_instance_valid(p1) or not is_instance_valid(p2):
		return
	round_locked = false
	reset_timer = 0.0
	status_label.text = "FIGHT!"
	p1.reset_fighter(PLAYER_ONE_START)
	p2.reset_fighter(PLAYER_TWO_START)
	p1_bar.set_health(p1.max_health)
	p2_bar.set_health(p2.max_health)
	_finish_round_intro()


func _finish_round_intro() -> void:
	# Round intro timing must freeze too; otherwise it could finish behind the pause menu.
	await get_tree().create_timer(INTRO_DELAY, false).timeout
	if not is_inside_tree():
		return
	if not round_locked and is_instance_valid(status_label):
		status_label.text = ""


# -------------------------------------------------------------------
# Arena rendering — neon city / open-source tournament stage
# -------------------------------------------------------------------

func _draw() -> void:
	if selecting:
		return

	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), BACKGROUND)

	# Soft stage glow and distant horizon.
	draw_circle(Vector2(640, 345), 250, Color(0.06, 0.20, 0.32, 0.10))
	draw_circle(Vector2(640, 355), 170, Color(0.08, 0.30, 0.43, 0.10))
	draw_rect(Rect2(0, 140, 1280, 290), Color("#0b1426"))

	# Stylized skyline.
	for i in range(12):
		var building_x := i * 112 - 10
		var building_height := 70 + ((i * 37 + 23) % 125)
		var building := Rect2(building_x, 430 - building_height, 86, building_height)
		draw_rect(building, Color("#101e33"))
		draw_rect(Rect2(building.position.x, building.position.y, building.size.x, 2), Color("#294765"))
		for row in range(2, int(building_height / 18)):
			for col in range(2, 5):
				var wx := building_x + col * 15
				var wy := 430 - building_height + row * 15
				var window_color := Color("#2c6785") if (i + row + col) % 3 == 0 else Color("#172d46")
				draw_rect(Rect2(wx, wy, 5, 7), window_color)

	# Big tournament signage.
	draw_rect(Rect2(400, 150, 480, 92), Color("#0d1a2b"))
	draw_rect(Rect2(400, 150, 480, 2), Color("#3b7596"))
	draw_rect(Rect2(400, 240, 480, 2), Color("#3b7596"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 190), "TUX COMBAT", HORIZONTAL_ALIGNMENT_CENTER, 1280, 34, Color("#8bdcff"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 220), "OPEN SOURCE • OPEN ARENA", HORIZONTAL_ALIGNMENT_CENTER, 1280, 14, Color("#7c9cb9"))

	# Floor and perspective grid.
	draw_rect(Rect2(0, 430, 1280, 290), FLOOR_COLOR)
	for x in range(-240, 1521, 80):
		draw_line(Vector2(640, 430), Vector2(x, 720), GRID_COLOR, 1.5, true)
	for y in range(452, 721, 28):
		var t := float(y - 430) / 290.0
		draw_line(Vector2(0, y), Vector2(1280, y), GRID_COLOR.darkened(0.18 + t * 0.25), 1.0, true)

	# Stage rails and luminous boundary lines.
	draw_line(Vector2(48, 430), Vector2(1232, 430), Color("#4d9ac0"), 3.0, true)
	draw_line(Vector2(70, 620), Vector2(1210, 620), Color("#5dcaef"), 4.0, true)
	draw_line(Vector2(70, 625), Vector2(1210, 625), Color(0.1, 0.55, 0.8, 0.25), 10.0, true)

	# Side pylons and little status lights.
	for x in [34.0, 1228.0]:
		draw_rect(Rect2(x, 300, 18, 150), Color("#172c43"))
		draw_rect(Rect2(x + 3, 308, 12, 4), ACCENT_BLUE)
		draw_rect(Rect2(x + 3, 322, 12, 4), ACCENT_GREEN)
		draw_rect(Rect2(x + 3, 336, 12, 4), Color("#ff657c"))
		draw_line(Vector2(x + 9, 350), Vector2(x + 9, 430), Color("#345a7b"), 2.0)

	draw_string(ThemeDB.fallback_font, Vector2(74, 401), "OPEN-SOURCE ARENA", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, ACCENT_BLUE)
	draw_string(ThemeDB.fallback_font, Vector2(1000, 401), "ROUND READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, ACCENT_GREEN)

	# Animated impact burst and debris, drawn in world space.
	for spark in hit_sparks:
		var pos: Vector2 = spark["position"]
		var life_ratio := clampf(float(spark["life"]) / 0.30, 0.0, 1.0)
		var color: Color = spark["color"]
		color.a = life_ratio
		var radius := 2.0 + (1.0 - life_ratio) * 4.0
		draw_circle(pos, radius + 2.0, Color(1.0, 1.0, 1.0, 0.20 * life_ratio))
		draw_circle(pos, radius, color)
		if spark["velocity"].length() < 1.0:
			var seed_angle := float(spark["seed"])
			var kind := String(spark.get("kind", "punch"))
			if kind == "punch":
				# Compact starburst for a clean, sharp fist impact.
				var points := PackedVector2Array()
				for ray in range(12):
					var angle := seed_angle + TAU * float(ray) / 12.0
					var distance := 19.0 if ray % 2 == 0 else 8.0
					points.append(pos + Vector2(cos(angle), sin(angle)) * distance * (1.0 - 0.18 * (1.0 - life_ratio)))
				draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.18 * life_ratio))
				for ray in range(8):
					var angle := seed_angle + TAU * float(ray) / 8.0
					draw_line(pos + Vector2(cos(angle), sin(angle)) * 8.0, pos + Vector2(cos(angle), sin(angle)) * (22.0 + 8.0 * (1.0 - life_ratio)), color, 2.5, true)
			else:
				# Wider double arc for the heavier, sweeping kick impact.
				var arc_radius := 18.0 + 12.0 * (1.0 - life_ratio)
				draw_arc(pos, arc_radius, seed_angle - 1.2, seed_angle + 1.2, 24, color, 3.5, true)
				draw_arc(pos, arc_radius * 0.62, seed_angle - 1.0, seed_angle + 1.0, 20, Color(color.r, color.g, color.b, 0.55 * life_ratio), 2.0, true)

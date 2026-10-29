
extends Node2D

const FighterScene = preload("res://scripts/fighter.gd")
const AeroHealthBarScript = preload("res://scripts/aero_health_bar.gd")

const CHARACTERS := [
	{
		"id": "tux",
		"name": "Tux",
		"description": "Linux penguin • balanced"
	},
	{
		"id": "gnu",
		"name": "GNU",
		"description": "GNU wildebeest • heavy"
	},
	{
		"id": "beastie",
		"name": "Beastie",
		"description": "BSD daemon • aggressive"
	},
	{
		"id": "puffy",
		"name": "Puffy",
		"description": "OpenBSD pufferfish • quick"
	}
]

const SCREEN_SIZE := Vector2(1280, 720)
const PLAYER_ONE_START := Vector2(360, 560)
const PLAYER_TWO_START := Vector2(920, 560)
const ROUND_DELAY := 2.0
const INTRO_DELAY := 0.75
const KNOCKBACK := 180.0
const HIT_VERTICAL_REACH := 100.0

const BACKGROUND := Color("#0b1020")
const FLOOR_COLOR := Color("#121a2b")
const GRID_COLOR := Color("#1d2942")
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


func _ready() -> void:
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
	background.position = Vector2.ZERO
	background.size = SCREEN_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_layer.add_child(background)

	var title := Label.new()
	title.text = "TUX COMBAT"
	title.position = Vector2(0, 70)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	selection_layer.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SELECT YOUR UNIX / LINUX FIGHTER"
	subtitle.position = Vector2(0, 135)
	subtitle.size = Vector2(1280, 35)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	selection_layer.add_child(subtitle)

	selection_label = Label.new()
	selection_label.position = Vector2(0, 575)
	selection_label.size = Vector2(1280, 40)
	selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_label.add_theme_font_size_override("font_size", 22)
	selection_layer.add_child(selection_label)

	for i in range(CHARACTERS.size()):
		var button := Button.new()

		button.text = "%s\n\n%s" % [
			CHARACTERS[i]["name"],
			CHARACTERS[i]["description"]
		]

		button.position = Vector2(70 + i * 300, 230)
		button.size = Vector2(250, 270)
		button.add_theme_font_size_override("font_size", 20)
		button.tooltip_text = "Choose %s" % CHARACTERS[i]["name"]
		button.pressed.connect(_select_character.bind(i))

		selection_layer.add_child(button)
		selection_buttons.append(button)

	_update_selection_visuals()


func _update_selection_visuals() -> void:
	for i in range(selection_buttons.size()):
		var button := selection_buttons[i]
		var character: Dictionary = CHARACTERS[i]

		var character_color := (
			PUFFY_YELLOW
			if character["id"] == "puffy"
			else Color.WHITE
		)

		button.add_theme_color_override("font_color", character_color)

		if i == selected_index:
			button.modulate = Color.WHITE
			button.text = "▶ %s ◀\n\n%s" % [
				character["name"],
				character["description"]
			]
		else:
			button.modulate = Color(0.65, 0.68, 0.75, 1.0)
			button.text = "%s\n\n%s" % [
				character["name"],
				character["description"]
			]

	selection_label.text = (
		"Selected: %s   •   ← / → to choose   •   ENTER to fight"
		% CHARACTERS[selected_index]["name"]
	)


func _input(event: InputEvent) -> void:
	if not selecting:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT:
				selected_index = (
					selected_index - 1 + CHARACTERS.size()
				) % CHARACTERS.size()
				_update_selection_visuals()

			KEY_RIGHT:
				selected_index = (
					selected_index + 1
				) % CHARACTERS.size()
				_update_selection_visuals()

			KEY_ENTER, KEY_KP_ENTER:
				_start_game(selected_index)


func _select_character(index: int) -> void:
	if index < 0 or index >= CHARACTERS.size():
		return

	selected_index = index
	_update_selection_visuals()
	_start_game(index)


func _start_game(player_choice: int) -> void:
	if not selecting:
		return

	if player_choice < 0 or player_choice >= CHARACTERS.size():
		return

	selecting = false

	if is_instance_valid(selection_layer):
		selection_layer.queue_free()

	_create_ui()
	_create_fighters(player_choice)
	queue_redraw()


# -------------------------------------------------------------------
# Fighters
# -------------------------------------------------------------------

func _create_fighters(player_choice: int) -> void:
	var player_data: Dictionary = CHARACTERS[player_choice]

	var cpu_choice := (
		player_choice + randi_range(1, CHARACTERS.size() - 1)
	) % CHARACTERS.size()

	var cpu_data: Dictionary = CHARACTERS[cpu_choice]

	p1 = FighterScene.new() as Fighter
	p1.add_to_group("fighters")
	add_child(p1)

	p1.setup(
		player_data["name"],
		1,
		false,
		player_data["id"]
	)
	p1.strike.connect(_on_strike)

	p2 = FighterScene.new() as Fighter
	p2.add_to_group("fighters")
	add_child(p2)

	p2.setup(
		cpu_data["name"],
		2,
		true,
		cpu_data["id"]
	)
	p2.strike.connect(_on_strike)

	controls_label.text = (
		"P1: A/D move • W jump • S crouch • J punch • K kick"
		+ "   |   CPU: %s" % cpu_data["name"]
	)

	p1_bar.set_fighter_label(p1.fighter_name)
	p2_bar.set_fighter_label(p2.fighter_name)

	_reset_round()


# -------------------------------------------------------------------
# Aero-style HUD
# -------------------------------------------------------------------

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var title := Label.new()
	title.text = "TUX COMBAT"
	title.position = Vector2(515, 7)
	title.size = Vector2(250, 35)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#d9f3ff"))
	layer.add_child(title)

	# Left player's Aero glass health bar.
	p1_bar = AeroHealthBarScript.new()
	p1_bar.position = Vector2(70, 43)
	p1_bar.size = Vector2(470, 38)
	p1_bar.setup("PLAYER 1", 1, 100)
	layer.add_child(p1_bar)

	# Right player's Aero glass health bar.
	p2_bar = AeroHealthBarScript.new()
	p2_bar.position = Vector2(740, 43)
	p2_bar.size = Vector2(470, 38)
	p2_bar.setup("CPU", 2, 100)
	layer.add_child(p2_bar)

	round_label = Label.new()
	round_label.position = Vector2(480, 84)
	round_label.size = Vector2(320, 30)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.add_theme_font_size_override("font_size", 20)
	round_label.add_theme_color_override("font_color", ACCENT_BLUE)
	layer.add_child(round_label)

	status_label = Label.new()
	status_label.position = Vector2(280, 575)
	status_label.size = Vector2(720, 60)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 26)
	layer.add_child(status_label)

	controls_label = Label.new()
	controls_label.position = Vector2(100, 675)
	controls_label.size = Vector2(1080, 30)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(controls_label)


# -------------------------------------------------------------------
# Game loop and rounds
# -------------------------------------------------------------------

func _process(delta: float) -> void:
	if selecting:
		return

	if not is_instance_valid(p1) or not is_instance_valid(p2):
		return

	p1_bar.set_health(p1.health)
	p2_bar.set_health(p2.health)

	round_label.text = "Round %d   •   %d - %d" % [
		round_number,
		p1_rounds,
		p2_rounds
	]

	if round_locked:
		reset_timer -= delta

		if reset_timer <= 0.0:
			if p1_rounds >= 2 or p2_rounds >= 2:
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


func _on_strike(
	attacker: Fighter,
	damage: int,
	reach: float,
	attack_type: String
) -> void:
	if round_locked:
		return

	if not is_instance_valid(attacker):
		return

	if attacker != p1 and attacker != p2:
		return

	if damage <= 0 or reach <= 0.0:
		return

	if attack_type != "punch" and attack_type != "kick":
		return

	var target: Fighter = p2 if attacker == p1 else p1

	if not is_instance_valid(target) or target.health <= 0:
		return

	var horizontal_distance := absf(
		target.position.x - attacker.position.x
	)

	var vertical_distance := absf(
		target.position.y - attacker.position.y
	)

	if horizontal_distance > reach:
		return

	if vertical_distance >= HIT_VERTICAL_REACH:
		return

	var target_offset := target.position.x - attacker.position.x

	# Prevent strikes from hitting a fighter behind the attacker.
	if target_offset * attacker.facing < -8.0:
		return

	var direction := signf(target_offset)

	if direction == 0.0:
		direction = attacker.facing

	target.take_damage(damage, direction * KNOCKBACK)


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
		status_label.text = "%s wins the match! 🐧" % winner.fighter_name
	else:
		status_label.text = "%s wins the round!" % winner.fighter_name


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
	await get_tree().create_timer(INTRO_DELAY).timeout

	if not is_inside_tree():
		return

	if not round_locked and is_instance_valid(status_label):
		status_label.text = ""


# -------------------------------------------------------------------
# Arena rendering
# -------------------------------------------------------------------

func _draw() -> void:
	if selecting:
		return

	draw_rect(
		Rect2(Vector2.ZERO, SCREEN_SIZE),
		BACKGROUND
	)

	draw_rect(
		Rect2(0, 430, 1280, 290),
		FLOOR_COLOR
	)

	for x in range(0, 1281, 80):
		draw_line(
			Vector2(x, 430),
			Vector2(x - 120, 720),
			GRID_COLOR,
			2.0
		)

	draw_line(
		Vector2(70, 620),
		Vector2(1210, 620),
		Color("#4f6b91"),
		6.0
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(80, 405),
		"OPEN-SOURCE ARENA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		ACCENT_BLUE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(1000, 405),
		"ROUND READY",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		ACCENT_GREEN
	)

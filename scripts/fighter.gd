
extends CharacterBody2D
class_name Fighter

signal strike(attacker: Fighter, damage: int, reach: float)

var fighter_name := "Fighter"
var character_id := "tux"
var player_id := 1
var is_cpu := false
var facing := 1.0

var max_health := 100
var health := 100

const SPEED := 340.0
const JUMP_SPEED := -720.0
const GRAVITY := 1800.0
const GROUND_Y := 560.0
const PUNCH_DAMAGE := 7
const KICK_DAMAGE := 10
const PUNCH_REACH := 105.0
const KICK_REACH := 125.0

var attack_cooldown := 0.0
var attack_flash := 0.0
var crouching := false
var stunned := 0.0
var ai_timer := 0.0
var ai_choice := 0

const OUTLINE := Color("#11131a")
const WHITE := Color("#fffaf0")
const SHADOW := Color("#080a10")
const GOLD := Color("#ffad28")

func setup(display_name: String, id: int, cpu: bool, style_id: String = "tux") -> void:
	fighter_name = display_name
	player_id = id
	is_cpu = cpu
	character_id = style_id
	health = max_health
	queue_redraw()

func reset_fighter(start_position: Vector2) -> void:
	position = start_position
	velocity = Vector2.ZERO
	health = max_health
	facing = 1.0 if start_position.x < 640.0 else -1.0
	attack_cooldown = 0.0
	attack_flash = 0.0
	stunned = 0.0
	crouching = false
	queue_redraw()

func _physics_process(delta: float) -> void:
	if stunned > 0.0:
		stunned -= delta
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if attack_flash > 0.0:
		attack_flash -= delta
		queue_redraw()

	var grounded := position.y >= GROUND_Y
	if grounded:
		position.y = GROUND_Y
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY * delta

	if stunned <= 0.0:
		if is_cpu:
			_process_cpu(delta)
		else:
			_process_player(grounded)

	move_and_slide()
	position.x = clamp(position.x, 100.0, 1180.0)
	if position.y > GROUND_Y:
		position.y = GROUND_Y
		velocity.y = 0.0
	if attack_flash <= 0.0:
		queue_redraw()

func _process_player(grounded: bool) -> void:
	var left := false
	var right := false
	var jump := false
	var down := false
	var punch := false
	var kick := false

	if player_id == 1:
		left = Input.is_key_pressed(KEY_A)
		right = Input.is_key_pressed(KEY_D)
		jump = Input.is_key_pressed(KEY_W)
		down = Input.is_key_pressed(KEY_S)
		punch = Input.is_key_pressed(KEY_J)
		kick = Input.is_key_pressed(KEY_K)
		if Input.get_connected_joypads().has(0):
			var axis := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
			left = left or axis < -0.35
			right = right or axis > 0.35
			jump = jump or Input.is_joy_button_pressed(0, JOY_BUTTON_Y)
			punch = punch or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
			kick = kick or Input.is_joy_button_pressed(0, JOY_BUTTON_B)

	var direction := float(right) - float(left)
	velocity.x = move_toward(velocity.x, direction * SPEED, 70.0)
	if direction != 0.0:
		facing = sign(direction)

	crouching = down and grounded
	if crouching:
		velocity.x *= 0.55
	if jump and grounded and not crouching:
		velocity.y = JUMP_SPEED
	if punch:
		_try_attack(PUNCH_DAMAGE, PUNCH_REACH, 0.24)
	elif kick:
		_try_attack(KICK_DAMAGE, KICK_REACH, 0.32)

func _process_cpu(delta: float) -> void:
	var opponents := get_tree().get_nodes_in_group("fighters")
	var target: Fighter = null
	for node in opponents:
		if node != self and node is Fighter:
			target = node
			break
	if target == null:
		return

	var distance := target.position.x - position.x
	var abs_distance := abs(distance)
	facing = 1.0 if distance >= 0.0 else -1.0
	if abs_distance > 150.0:
		velocity.x = move_toward(velocity.x, facing * SPEED * 0.68, 45.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 80.0)

	ai_timer -= delta
	if ai_timer <= 0.0:
		ai_timer = randf_range(0.25, 0.7)
		ai_choice = randi_range(0, 3)
	if abs_distance < 145.0 and ai_choice <= 1:
		_try_attack(KICK_DAMAGE if ai_choice == 1 else PUNCH_DAMAGE, KICK_REACH if ai_choice == 1 else PUNCH_REACH, 0.3)
	elif abs_distance > 250.0 and ai_choice == 2 and position.y >= GROUND_Y:
		velocity.y = JUMP_SPEED

func _try_attack(damage: int, reach: float, recovery: float) -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = recovery
	attack_flash = 0.12
	strike.emit(self, damage, reach)

func take_damage(amount: int, knockback: float) -> void:
	if health <= 0:
		return
	health = max(0, health - amount)
	stunned = 0.16
	velocity.x += knockback
	queue_redraw()

# -------------------------------------------------------------------
# Procedural mascot artwork
# Coordinates are local to the fighter; the feet sit around y = 100.
# -------------------------------------------------------------------

func _draw() -> void:
	match character_id:
		"gnu":
			_draw_gnu()
		"beastie":
			_draw_beastie()
		"puffy":
			_draw_puffy()
		_:
			_draw_tux()

func _ellipse(center: Vector2, rx: float, ry: float, color: Color, segments: int = 32) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)

func _poly(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _stroke(points: Array[Vector2], color: Color, width: float = 5.0) -> void:
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width, true)
		draw_circle(points[i], width * 0.5, color)
	if not points.is_empty():
		draw_circle(points[points.size() - 1], width * 0.5, color)

func _eye(center: Vector2, radius: float = 8.0) -> void:
	_ellipse(center + Vector2(1, 1), radius + 2, radius + 2, OUTLINE)
	_ellipse(center, radius, radius, WHITE)
	_ellipse(center + Vector2(2.0 * facing, 0), radius * 0.48, radius * 0.62, OUTLINE)
	_ellipse(center + Vector2(3.0 * facing, -2), radius * 0.18, radius * 0.2, WHITE)

func _draw_attack_effect(color: Color) -> void:
	if attack_flash <= 0.0:
		return
	var f := facing
	_stroke([
		Vector2(37 * f, -12),
		Vector2(65 * f, -25),
		Vector2(92 * f, -21),
		Vector2(111 * f, -35)
	], color, 7.0)
	draw_circle(Vector2(114 * f, -36), 7, WHITE)
	draw_circle(Vector2(114 * f, -36), 4, color)

func _draw_feet(color: Color, width: float = 19.0) -> void:
	var y := 79.0 if not crouching else 83.0
	_stroke([Vector2(-22, 55), Vector2(-29, y)], OUTLINE, width + 5)
	_stroke([Vector2(22, 55), Vector2(29, y)], OUTLINE, width + 5)
	_stroke([Vector2(-22, 55), Vector2(-29, y)], color, width)
	_stroke([Vector2(22, 55), Vector2(29, y)], color, width)

func _draw_tux() -> void:
	var black := Color("#171c24")
	var belly := Color("#fffaf0")
	var orange := Color("#ff9f1c")

	# Feet and flippers sit behind the body.
	_draw_feet(orange, 20)
	_stroke([Vector2(-34, -5), Vector2(-62, 12), Vector2(-68, 21)], OUTLINE, 23)
	_stroke([Vector2(34, -5), Vector2(62, 12), Vector2(68, 21)], OUTLINE, 23)
	_stroke([Vector2(-34, -5), Vector2(-62, 12), Vector2(-68, 21)], black, 17)
	_stroke([Vector2(34, -5), Vector2(62, 12), Vector2(68, 21)], black, 17)

	# One connected-looking penguin body with a large white chest.
	_ellipse(Vector2(0, 17), 51, 64, OUTLINE)
	_ellipse(Vector2(0, 15), 46, 59, black)
	_ellipse(Vector2(0, 24), 32, 43, belly)

	# Head and face.
	_ellipse(Vector2(0, -66), 51, 49, OUTLINE)
	_ellipse(Vector2(0, -66), 46, 44, black)
	_ellipse(Vector2(0, -48), 34, 29, belly)

	var f := facing
	_poly([
		Vector2(28 * f, -69),
		Vector2(52 * f, -61),
		Vector2(28 * f, -53)
	], OUTLINE)
	_poly([
		Vector2(30 * f, -68),
		Vector2(48 * f, -61),
		Vector2(30 * f, -55)
	], orange)

	_eye(Vector2(18 * f, -81), 8)
	_ellipse(Vector2(-15 * f, -83), 5, 6, Color("#11131a"))
	_draw_attack_effect(orange)

func _draw_gnu() -> void:
	var fur := Color("#7c8795")
	var light_fur := Color("#d8d2c4")
	var muzzle := Color("#4b515c")
	var horn := Color("#e8dfca")
	var hoof := Color("#30343c")
	var f := facing

	_draw_feet(hoof, 18)

	# Shaggy shoulders, back and beard.
	_ellipse(Vector2(0, 17), 54, 60, OUTLINE)
	_ellipse(Vector2(0, 15), 49, 55, fur)
	_ellipse(Vector2(-4, 23), 34, 40, light_fur)

	_poly([
		Vector2(-31, -20), Vector2(-15, -8), Vector2(-9, 6),
		Vector2(0, -7), Vector2(10, 8), Vector2(19, -9),
		Vector2(30, -17), Vector2(22, 24), Vector2(-21, 26)
	], fur)

	# Long wildebeest muzzle.
	_ellipse(Vector2(24 * f, -59), 30, 23, OUTLINE)
	_ellipse(Vector2(25 * f, -60), 27, 19, fur)
	_ellipse(Vector2(43 * f, -52), 18, 13, muzzle)
	_ellipse(Vector2(52 * f, -55), 3, 3, OUTLINE)

	# Wide, curved horns with pale tips.
	_stroke([
		Vector2(-26, -88), Vector2(-39, -107),
		Vector2(-49, -124), Vector2(-46, -137)
	], OUTLINE, 14)
	_stroke([
		Vector2(-26, -88), Vector2(-39, -107),
		Vector2(-49, -124), Vector2(-46, -137)
	], horn, 9)
	_stroke([
		Vector2(20, -88), Vector2(34, -105),
		Vector2(45, -121), Vector2(43, -135)
	], OUTLINE, 14)
	_stroke([
		Vector2(20, -88), Vector2(34, -105),
		Vector2(45, -121), Vector2(43, -135)
	], horn, 9)

	# Forelock and beard.
	_poly([
		Vector2(-22, -94), Vector2(-7, -104),
		Vector2(4, -91), Vector2(18, -101),
		Vector2(29, -82), Vector2(14, -72),
		Vector2(-13, -75)
	], Color("#555d68"))
	_poly([
		Vector2(6 * f, -43), Vector2(24 * f, -39),
		Vector2(16 * f, -20), Vector2(5 * f, -30)
	], OUTLINE)
	_poly([
		Vector2(8 * f, -43), Vector2(22 * f, -39),
		Vector2(16 * f, -25)
	], Color("#5c6470"))

	_eye(Vector2(18 * f, -76), 7)
	_ellipse(Vector2(35 * f, -45), 3, 2, OUTLINE)
	_stroke([Vector2(-33, -7), Vector2(-55, 6)], OUTLINE, 17)
	_stroke([Vector2(-33, -7), Vector2(-55, 6)], fur, 11)
	_stroke([Vector2(33, -7), Vector2(55, 6)], OUTLINE, 17)
	_stroke([Vector2(33, -7), Vector2(55, 6)], fur, 11)
	_draw_attack_effect(GOLD)

func _draw_beastie() -> void:
	var red := Color("#c92332")
	var dark_red := Color("#7e1725")
	var cream := Color("#f5e8cf")
	var orange := Color("#ff8b32")
	var f := facing

	_draw_feet(orange, 18)

	# Tail curls upward behind the body and ends in a devilish spade.
	_stroke([
		Vector2(-34, 38), Vector2(-55, 27),
		Vector2(-66, 8), Vector2(-62, -6),
		Vector2(-49, -7)
	], OUTLINE, 9)
	_stroke([
		Vector2(-34, 38), Vector2(-55, 27),
		Vector2(-66, 8), Vector2(-62, -6),
		Vector2(-49, -7)
	], red, 5)
	_poly([
		Vector2(-49, -13), Vector2(-38, -7),
		Vector2(-49, 2), Vector2(-61, -7)
	], OUTLINE)
	_poly([
		Vector2(-49, -11), Vector2(-41, -7),
		Vector2(-49, -1), Vector2(-57, -7)
	], red)

	# Compact red imp body.
	_ellipse(Vector2(0, 17), 53, 61, OUTLINE)
	_ellipse(Vector2(0, 15), 48, 56, red)
	_ellipse(Vector2(0, 23), 32, 40, dark_red)
	_ellipse(Vector2(4, 22), 26, 33, red)

	# Pointed ears.
	_poly([
		Vector2(-35, -76), Vector2(-64, -96),
		Vector2(-55, -63), Vector2(-37, -53)
	], OUTLINE)
	_poly([
		Vector2(-36, -74), Vector2(-58, -90),
		Vector2(-52, -65), Vector2(-38, -58)
	], red)
	_poly([
		Vector2(34, -76), Vector2(63, -98),
		Vector2(54, -62), Vector2(36, -53)
	], OUTLINE)
	_poly([
		Vector2(35, -74), Vector2(57, -91),
		Vector2(51, -64), Vector2(37, -58)
	], red)

	# Curved devil horns.
	_stroke([
		Vector2(-22, -88), Vector2(-31, -106),
		Vector2(-29, -123), Vector2(-40, -133)
	], OUTLINE, 16)
	_stroke([
		Vector2(-22, -88), Vector2(-31, -106),
		Vector2(-29, -123), Vector2(-40, -133)
	], orange, 10)
	_stroke([
		Vector2(21, -88), Vector2(30, -106),
		Vector2(28, -123), Vector2(39, -133)
	], OUTLINE, 16)
	_stroke([
		Vector2(21, -88), Vector2(30, -106),
		Vector2(28, -123), Vector2(39, -133)
	], orange, 10)

	# Face and cream muzzle.
	_ellipse(Vector2(0, -67), 43, 37, OUTLINE)
	_ellipse(Vector2(0, -68), 39, 33, red)
	_ellipse(Vector2(23 * f, -52), 22, 16, OUTLINE)
	_ellipse(Vector2(23 * f, -52), 18, 12, cream)

	_eye(Vector2(16 * f, -78), 8)
	_ellipse(Vector2(35 * f, -53), 3, 2, OUTLINE)

	# Little grin.
	_stroke([
		Vector2(12 * f, -43), Vector2(22 * f, -40),
		Vector2(32 * f, -44)
	], OUTLINE, 2.5)

	_stroke([Vector2(-34, -5), Vector2(-59, 9)], OUTLINE, 20)
	_stroke([Vector2(-34, -5), Vector2(-59, 9)], red, 14)
	_stroke([Vector2(34, -5), Vector2(59, 9)], OUTLINE, 20)
	_stroke([Vector2(34, -5), Vector2(59, 9)], red, 14)
	_draw_attack_effect(orange)

func _draw_puffy() -> void:
	var blue := Color("#2585df")
	var deep_blue := Color("#1453a0")
	var light_blue := Color("#7dc8ff")
	var belly := Color("#f5e9ce")
	var fin := Color("#46a8f5")
	var f := facing

	# Tail fin behind the fish.
	_poly([
		Vector2(-37, 9), Vector2(-65, -5),
		Vector2(-71, 13), Vector2(-64, 31),
		Vector2(-39, 25)
	], OUTLINE)
	_poly([
		Vector2(-39, 10), Vector2(-63, 0),
		Vector2(-66, 13), Vector2(-61, 25),
		Vector2(-40, 22)
	], fin)

	# Feet are small fish-like fins rather than penguin feet.
	_poly([
		Vector2(-28, 50), Vector2(-43, 75),
		Vector2(-15, 68), Vector2(-8, 53)
	], OUTLINE)
	_poly([
		Vector2(-26, 52), Vector2(-37, 69),
		Vector2(-17, 64), Vector2(-10, 53)
	], fin)
	_poly([
		Vector2(28, 50), Vector2(43, 75),
		Vector2(15, 68), Vector2(8, 53)
	], OUTLINE)
	_poly([
		Vector2(26, 52), Vector2(37, 69),
		Vector2(17, 64), Vector2(10, 53)
	], fin)

	# A round, broad fish silhouette.
	_ellipse(Vector2(0, 0), 57, 69, OUTLINE)
	_ellipse(Vector2(0, 0), 52, 64, blue)
	_ellipse(Vector2(0, 22), 37, 39, belly)

	# Side fins.
	_poly([
		Vector2(-45, -15), Vector2(-67, -31),
		Vector2(-63, -4), Vector2(-45, 7)
	], OUTLINE)
	_poly([
		Vector2(-45, -14), Vector2(-62, -26),
		Vector2(-59, -5), Vector2(-45, 2)
	], fin)
	_poly([
		Vector2(45, -15), Vector2(67, -31),
		Vector2(63, -4), Vector2(45, 7)
	], OUTLINE)
	_poly([
		Vector2(45, -14), Vector2(62, -26),
		Vector2(59, -5), Vector2(45, 2)
	], fin)

	# Distinctive pufferfish spines around the outline.
	for i in range(9):
		var angle := PI + float(i) * PI / 8.0
		var inner := Vector2(cos(angle) * 52, sin(angle) * 62)
		var outer := Vector2(cos(angle) * 66, sin(angle) * 78)
		draw_line(inner, outer, OUTLINE, 9, true)
		draw_line(inner, outer, light_blue, 5, true)

	for i in range(7):
		var angle := -0.15 + float(i) * PI / 7.0
		var inner := Vector2(cos(angle) * 51, sin(angle) * 61)
		var outer := Vector2(cos(angle) * 64, sin(angle) * 76)
		draw_line(inner, outer, OUTLINE, 8, true)
		draw_line(inner, outer, light_blue, 4, true)

	# Eyes, tiny fish mouth and cheek marks.
	_eye(Vector2(19 * f, -24), 8)
	_ellipse(Vector2(-11 * f, -25), 6, 7, OUTLINE)
	_ellipse(Vector2(31 * f, -5), 6, 4, OUTLINE)
	_ellipse(Vector2(32 * f, -6), 3, 2, Color("#ffb2a5"))

	# A few scale-like spots make the silhouette feel less flat.
	_ellipse(Vector2(-25, 4), 4, 4, light_blue)
	_ellipse(Vector2(-31, 19), 3, 3, light_blue)
	_ellipse(Vector2(13, 38), 4, 3, Color("#dfd0b3"))
	_ellipse(Vector2(-9, 43), 3, 3, Color("#dfd0b3"))

	# The attack swipe reads as a punch or fin strike.
	_draw_attack_effect(Color("#9ce8ff"))

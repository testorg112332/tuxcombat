
extends CharacterBody2D
class_name Fighter

signal strike(attacker: Fighter, damage: int, reach: float, attack_type: String)

var fighter_name := "Fighter"
var character_id := "tux"
var player_id := 1
var is_cpu := false
var facing := 1.0

var max_health := 100
var health := 100

const SPEED := 340.0
const PLAYER_ACCELERATION := 4200.0
const PLAYER_BRAKING := 4200.0
const CPU_ACCELERATION := 2700.0
const CPU_BRAKING := 4800.0
const JUMP_SPEED := -720.0
const GRAVITY := 1800.0
const GROUND_Y := 560.0
const ARENA_LEFT := 100.0
const ARENA_RIGHT := 1180.0
const ARENA_CENTER_X := 640.0
const PUNCH_DAMAGE := 7
const KICK_DAMAGE := 10
const PUNCH_REACH := 105.0
const KICK_REACH := 125.0

var attack_cooldown := 0.0
var attack_flash := 0.0
var last_attack_type := ""
var crouching := false
var stunned := 0.0
var ai_timer := 0.0
var ai_choice := 0

const OUTLINE := Color("#11131a")
const WHITE := Color("#fffaf0")
const SHADOW := Color("#080a10")
const GOLD := Color("#ffad28")

# Puffy's palette is deliberately yellow.
const PUFFY_YELLOW := Color("#ffdf32")
const PUFFY_DARK_YELLOW := Color("#d99a00")
const PUFFY_LIGHT_YELLOW := Color("#fff5a6")
const PUFFY_BELLY := Color("#fff0c2")
const PUFFY_FIN := Color("#ffb91f")
const PUFFY_CHEEK := Color("#ff9f9a")


func setup(display_name: String, id: int, cpu: bool, style_id: String = "tux") -> void:
	fighter_name = display_name
	player_id = id
	is_cpu = cpu
	character_id = style_id
	max_health = 135 if character_id.begins_with("boss_") else 100
	health = max_health
	queue_redraw()


func reset_fighter(start_position: Vector2) -> void:
	position = start_position
	velocity = Vector2.ZERO
	health = max_health
	facing = 1.0 if start_position.x < ARENA_CENTER_X else -1.0
	attack_cooldown = 0.0
	attack_flash = 0.0
	last_attack_type = ""
	stunned = 0.0
	ai_timer = 0.0
	ai_choice = 0
	crouching = false
	queue_redraw()


func _physics_process(delta: float) -> void:
	stunned = maxf(0.0, stunned - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	if attack_flash > 0.0:
		attack_flash = maxf(0.0, attack_flash - delta)
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
			_process_player(grounded, delta)

	move_and_slide()
	position.x = clampf(position.x, ARENA_LEFT, ARENA_RIGHT)

	if position.y > GROUND_Y:
		position.y = GROUND_Y
		velocity.y = 0.0

	if attack_flash <= 0.0:
		queue_redraw()


func _process_player(grounded: bool, delta: float) -> void:
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
	var acceleration := PLAYER_ACCELERATION if direction != 0.0 else PLAYER_BRAKING
	velocity.x = move_toward(velocity.x, direction * SPEED, acceleration * delta)

	if direction != 0.0:
		facing = signf(direction)

	crouching = down and grounded

	if crouching:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			PLAYER_BRAKING * 0.45 * delta
		)

	if jump and grounded and not crouching:
		velocity.y = JUMP_SPEED

	if punch:
		_try_attack(PUNCH_DAMAGE, PUNCH_REACH, 0.24, "punch")
	elif kick:
		_try_attack(KICK_DAMAGE, KICK_REACH, 0.32, "kick")


func _process_cpu(delta: float) -> void:
	var target: Fighter
	var closest_distance := INF

	for node in get_tree().get_nodes_in_group("fighters"):
		if node == self or not node is Fighter:
			continue

		var candidate := node as Fighter

		if candidate.health <= 0:
			continue

		var candidate_distance := absf(candidate.position.x - position.x)

		if candidate_distance < closest_distance:
			closest_distance = candidate_distance
			target = candidate

	if not is_instance_valid(target):
		velocity.x = move_toward(velocity.x, 0.0, CPU_BRAKING * delta)
		return

	var distance := target.position.x - position.x
	var abs_distance := absf(distance)

	facing = 1.0 if distance >= 0.0 else -1.0

	if abs_distance > 150.0:
		velocity.x = move_toward(
			velocity.x,
			facing * SPEED * 0.68,
			CPU_ACCELERATION * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			CPU_BRAKING * delta
		)

	ai_timer -= delta

	if ai_timer <= 0.0:
		ai_timer = randf_range(0.25, 0.7)
		ai_choice = randi_range(0, 3)

	if abs_distance < 145.0 and ai_choice <= 1:
		if ai_choice == 1:
			_try_attack(KICK_DAMAGE, KICK_REACH, 0.3, "kick")
		else:
			_try_attack(PUNCH_DAMAGE, PUNCH_REACH, 0.3, "punch")
	elif abs_distance > 250.0 and ai_choice == 2 and position.y >= GROUND_Y:
		velocity.y = JUMP_SPEED


func _try_attack(
	damage: int,
	reach: float,
	recovery: float,
	attack_type: String
) -> void:
	if attack_cooldown > 0.0:
		return

	var adjusted_reach := reach
	var adjusted_damage := damage

	# Distro bosses hit harder and have a little more reach.
	if character_id.begins_with("boss_"):
		adjusted_damage = roundi(float(damage) * 1.25)
		adjusted_reach += 12.0

	# Tux's attacks use tighter ranges than the other fighters.
	if character_id == "tux":
		if attack_type == "punch":
			adjusted_reach = 82.0
		elif attack_type == "kick":
			adjusted_reach = 100.0

	attack_cooldown = recovery
	attack_flash = 0.16
	last_attack_type = attack_type

	strike.emit(self, adjusted_damage, adjusted_reach, attack_type)
	queue_redraw()


func take_damage(amount: int, knockback: float) -> void:
	if health <= 0 or amount <= 0:
		return

	health = maxi(0, health - amount)
	stunned = maxf(stunned, 0.16)
	velocity.x += knockback
	queue_redraw()


# -------------------------------------------------------------------
# Procedural mascot artwork
# Coordinates are local to the fighter; the feet sit around y = 100.
# -------------------------------------------------------------------

func _draw() -> void:
	# Subtle procedural motion adds life without requiring imported sprite sheets.
	var tick := float(Time.get_ticks_msec()) / 1000.0
	var moving := absf(velocity.x) > 35.0 and position.y >= GROUND_Y - 2.0
	var bob := sin(tick * (12.0 if moving else 2.6)) * (2.5 if moving else 1.0)
	var squash := Vector2(1.0, 1.0)
	if crouching:
		squash = Vector2(1.07, 0.84)
	elif moving:
		squash = Vector2(0.97, 1.03)
	if attack_flash > 0.0:
		squash.x *= 1.06
		squash.y *= 0.97
	var lean := -0.09 * facing if attack_flash > 0.0 else 0.025 * sin(tick * 2.0)
	draw_set_transform(Vector2(0, bob), lean, squash)
	_ellipse(Vector2(0, 82), 30, 6, Color(0.0, 0.0, 0.0, 0.25))
	match character_id:
		"gnu":
			_draw_gnu()
		"beastie":
			_draw_beastie()
		"puffy":
			_draw_puffy()
		"boss_arch":
			_draw_arch_boss()
		"boss_ubuntu":
			_draw_ubuntu_boss()
		"boss_fedora":
			_draw_fedora_boss()
		"boss_debian":
			_draw_debian_boss()
		_:
			_draw_tux()


func _ellipse(
	center: Vector2,
	rx: float,
	ry: float,
	color: Color,
	segments: int = 32
) -> void:
	var safe_segments := maxi(3, segments)
	var points := PackedVector2Array()

	for i in range(safe_segments):
		var angle := TAU * float(i) / float(safe_segments)
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
	_ellipse(
		center + Vector2(2.0 * facing, 0),
		radius * 0.48,
		radius * 0.62,
		OUTLINE
	)
	_ellipse(
		center + Vector2(3.0 * facing, -2),
		radius * 0.18,
		radius * 0.2,
		WHITE
	)


func _draw_attack_effect(color: Color) -> void:
	if attack_flash <= 0.0:
		return

	var f := facing
	var progress := 1.0 - clampf(attack_flash / 0.16, 0.0, 1.0)
	var punch_color := color.lightened(0.22)
	var kick_color := Color("#ffd43b") if character_id != "boss_ubuntu" else Color("#ff9b65")

	if last_attack_type == "punch":
		# Forward arm with a large glove/fist. The arm extends during the punch.
		var fist := Vector2((62.0 + 26.0 * progress) * f, -34.0 - 9.0 * progress)
		var elbow := Vector2((43.0 + 10.0 * progress) * f, -23.0 - 4.0 * progress)
		_stroke([Vector2(27.0 * f, -12.0), elbow, fist], OUTLINE, 22.0)
		_stroke([Vector2(27.0 * f, -12.0), elbow, fist], punch_color, 15.0)
		_ellipse(fist, 14.0, 12.0, OUTLINE)
		_ellipse(fist, 10.0, 9.0, WHITE)
		_ellipse(fist + Vector2(2.0 * f, -1.0), 5.0, 5.0, punch_color)
		# Short speed lines make the punch read as a forward strike.
		for i in range(3):
			var y := -42.0 + float(i) * 9.0
			_stroke([
				Vector2((fist.x - 30.0 * f), y),
				Vector2((fist.x - (18.0 + float(i) * 2.0) * f), y - 2.0)
			], punch_color, 2.5)
	else:
		# A separate low sweeping kick: hip -> knee -> extended foot.
		var knee := Vector2((36.0 + 12.0 * progress) * f, 30.0 - 8.0 * progress)
		var foot := Vector2((62.0 + 34.0 * progress) * f, 22.0 - 27.0 * progress)
		_stroke([Vector2(17.0 * f, 32.0), knee, foot], OUTLINE, 24.0)
		_stroke([Vector2(17.0 * f, 32.0), knee, foot], kick_color, 16.0)
		_ellipse(foot, 17.0, 9.0, OUTLINE)
		_ellipse(foot + Vector2(2.0 * f, -1.0), 12.0, 5.5, WHITE)
		# Curved-looking swoosh streaks distinguish the kick from the punch.
		_stroke([
			Vector2((foot.x - 30.0 * f), foot.y - 20.0),
			Vector2((foot.x - 16.0 * f), foot.y - 27.0),
			Vector2((foot.x - 2.0 * f), foot.y - 23.0)
		], kick_color, 4.0)
		_stroke([
			Vector2((foot.x - 25.0 * f), foot.y + 15.0),
			Vector2((foot.x - 12.0 * f), foot.y + 20.0),
			Vector2((foot.x + 1.0 * f), foot.y + 14.0)
		], kick_color.darkened(0.12), 3.0)


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
	var f := facing

	_draw_feet(orange, 20)

	# Arms.
	_stroke([Vector2(-34, -5), Vector2(-62, 12), Vector2(-68, 21)], OUTLINE, 23)
	_stroke([Vector2(34, -5), Vector2(62, 12), Vector2(68, 21)], OUTLINE, 23)
	_stroke([Vector2(-34, -5), Vector2(-62, 12), Vector2(-68, 21)], black, 17)
	_stroke([Vector2(34, -5), Vector2(62, 12), Vector2(68, 21)], black, 17)

	# Body.
	_ellipse(Vector2(0, 17), 51, 64, OUTLINE)
	_ellipse(Vector2(0, 15), 46, 59, black)
	_ellipse(Vector2(0, 24), 32, 43, belly)

	# Head.
	_ellipse(Vector2(0, -66), 51, 49, OUTLINE)
	_ellipse(Vector2(0, -66), 46, 44, black)
	_ellipse(Vector2(0, -48), 34, 29, belly)

	# Beak.
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

	# Eyes.
	_eye(Vector2(18 * f, -81), 8)
	_ellipse(Vector2(-15 * f, -83), 5, 6, Color("#11131a"))

	# Keep attack effects on top of the character.
	_draw_attack_effect(orange)


func _draw_gnu() -> void:
	var fur := Color("#7c8795")
	var light_fur := Color("#d8d2c4")
	var muzzle := Color("#4b515c")
	var horn := Color("#e8dfca")
	var hoof := Color("#30343c")
	var f := facing

	_draw_feet(hoof, 18)

	_ellipse(Vector2(0, 17), 54, 60, OUTLINE)
	_ellipse(Vector2(0, 15), 49, 55, fur)
	_ellipse(Vector2(-4, 23), 34, 40, light_fur)

	_poly([
		Vector2(-31, -20), Vector2(-15, -8), Vector2(-9, 6),
		Vector2(0, -7), Vector2(10, 8), Vector2(19, -9),
		Vector2(30, -17), Vector2(22, 24), Vector2(-21, 26)
	], fur)

	_ellipse(Vector2(24 * f, -59), 30, 23, OUTLINE)
	_ellipse(Vector2(25 * f, -60), 27, 19, fur)
	_ellipse(Vector2(43 * f, -52), 18, 13, muzzle)
	_ellipse(Vector2(52 * f, -55), 3, 3, OUTLINE)

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

	_ellipse(Vector2(0, 17), 53, 61, OUTLINE)
	_ellipse(Vector2(0, 15), 48, 56, red)
	_ellipse(Vector2(0, 23), 32, 40, dark_red)
	_ellipse(Vector2(4, 22), 26, 33, red)

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

	_ellipse(Vector2(0, -67), 43, 37, OUTLINE)
	_ellipse(Vector2(0, -68), 39, 33, red)
	_ellipse(Vector2(23 * f, -52), 22, 16, OUTLINE)
	_ellipse(Vector2(23 * f, -52), 18, 12, cream)

	_eye(Vector2(16 * f, -78), 8)
	_ellipse(Vector2(35 * f, -53), 3, 2, OUTLINE)

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
	var f := facing

	# Tail fin.
	_poly([
		Vector2(-37, 9), Vector2(-65, -5),
		Vector2(-71, 13), Vector2(-64, 31),
		Vector2(-39, 25)
	], OUTLINE)

	_poly([
		Vector2(-39, 10), Vector2(-63, 0),
		Vector2(-66, 13), Vector2(-61, 25),
		Vector2(-40, 22)
	], PUFFY_FIN)

	# Bottom fins.
	_poly([
		Vector2(-28, 50), Vector2(-43, 75),
		Vector2(-15, 68), Vector2(-8, 53)
	], OUTLINE)

	_poly([
		Vector2(-26, 52), Vector2(-37, 69),
		Vector2(-17, 64), Vector2(-10, 53)
	], PUFFY_FIN)

	_poly([
		Vector2(28, 50), Vector2(43, 75),
		Vector2(15, 68), Vector2(8, 53)
	], OUTLINE)

	_poly([
		Vector2(26, 52), Vector2(37, 69),
		Vector2(17, 64), Vector2(10, 53)
	], PUFFY_FIN)

	# Main yellow body and cream belly.
	_ellipse(Vector2(0, 0), 57, 69, OUTLINE)
	_ellipse(Vector2(0, 0), 52, 64, PUFFY_YELLOW)
	_ellipse(Vector2(-8, -12), 35, 35, PUFFY_LIGHT_YELLOW)
	_ellipse(Vector2(0, 22), 37, 39, PUFFY_BELLY)

	# Side fins.
	_poly([
		Vector2(-45, -15), Vector2(-67, -31),
		Vector2(-63, -4), Vector2(-45, 7)
	], OUTLINE)

	_poly([
		Vector2(-45, -14), Vector2(-62, -26),
		Vector2(-59, -5), Vector2(-45, 2)
	], PUFFY_FIN)

	_poly([
		Vector2(45, -15), Vector2(67, -31),
		Vector2(63, -4), Vector2(45, 7)
	], OUTLINE)

	_poly([
		Vector2(45, -14), Vector2(62, -26),
		Vector2(59, -5), Vector2(45, 2)
	], PUFFY_FIN)

	# Spines.
	for i in range(9):
		var angle := PI + float(i) * PI / 8.0
		var inner := Vector2(cos(angle) * 52, sin(angle) * 62)
		var outer := Vector2(cos(angle) * 66, sin(angle) * 78)
		draw_line(inner, outer, OUTLINE, 9, true)
		draw_line(inner, outer, PUFFY_LIGHT_YELLOW, 5, true)

	for i in range(7):
		var angle := -0.15 + float(i) * PI / 7.0
		var inner := Vector2(cos(angle) * 51, sin(angle) * 61)
		var outer := Vector2(cos(angle) * 64, sin(angle) * 76)
		draw_line(inner, outer, OUTLINE, 8, true)
		draw_line(inner, outer, PUFFY_LIGHT_YELLOW, 4, true)

	# Face.
	_eye(Vector2(19 * f, -24), 8)
	_ellipse(Vector2(-11 * f, -25), 6, 7, OUTLINE)
	_ellipse(Vector2(31 * f, -5), 6, 4, OUTLINE)
	_ellipse(Vector2(32 * f, -6), 3, 2, PUFFY_CHEEK)

	# Yellow scales and details.
	_ellipse(Vector2(-25, 4), 4, 4, PUFFY_LIGHT_YELLOW)
	_ellipse(Vector2(-31, 19), 3, 3, PUFFY_DARK_YELLOW)
	_ellipse(Vector2(13, 38), 4, 3, PUFFY_DARK_YELLOW)
	_ellipse(Vector2(-9, 43), 3, 3, PUFFY_DARK_YELLOW)

	_draw_attack_effect(PUFFY_LIGHT_YELLOW)


# -------------------------------------------------------------------
# Distro bosses — original fighter silhouettes with recognizable logo cues.
# -------------------------------------------------------------------

func _draw_arch_boss() -> void:
	var blue := Color("#1793d1")
	_draw_feet(Color("#dceefa"), 22)
	_ellipse(Vector2(0, 15), 57, 63, OUTLINE)
	_ellipse(Vector2(0, 12), 51, 57, Color("#0d4265"))
	_ellipse(Vector2(0, -67), 48, 47, OUTLINE)
	_ellipse(Vector2(0, -68), 43, 42, blue)
	# Arch's angular A mark, integrated into the helmet/faceplate.
	_poly([Vector2(-29, -42), Vector2(-4, -101), Vector2(8, -101), Vector2(32, -42), Vector2(17, -42), Vector2(3, -78), Vector2(-12, -42)], WHITE)
	_poly([Vector2(-5, -56), Vector2(4, -56), Vector2(8, -46), Vector2(-9, -46)], Color("#0d4265"))
	_stroke([Vector2(-34, -7), Vector2(-54, 10)], OUTLINE, 22)
	_stroke([Vector2(-34, -7), Vector2(-54, 10)], blue, 15)
	_stroke([Vector2(34, -7), Vector2(54, 10)], OUTLINE, 22)
	_stroke([Vector2(34, -7), Vector2(54, 10)], blue, 15)
	_draw_attack_effect(WHITE)


func _draw_ubuntu_boss() -> void:
	var orange := Color("#e95420")
	_draw_feet(Color("#3a2020"), 22)
	_ellipse(Vector2(0, 15), 58, 64, OUTLINE)
	_ellipse(Vector2(0, 12), 52, 58, Color("#772d21"))
	_ellipse(Vector2(0, -67), 48, 47, OUTLINE)
	_ellipse(Vector2(0, -68), 43, 42, orange)
	# Three white nodes orbiting the Ubuntu-like central ring.
	draw_arc(Vector2(0, -68), 24.0, -0.5, TAU - 0.5, 48, WHITE, 5.0, true)
	for angle in [-PI / 2.0, PI / 6.0, 5.0 * PI / 6.0]:
		var node_pos := Vector2(cos(angle) * 24.0, -68.0 + sin(angle) * 24.0)
		_ellipse(node_pos, 6.5, 6.5, WHITE)
	_ellipse(Vector2(0, -68), 8, 8, orange)
	_stroke([Vector2(-34, -7), Vector2(-54, 10)], OUTLINE, 22)
	_stroke([Vector2(-34, -7), Vector2(-54, 10)], orange, 15)
	_stroke([Vector2(34, -7), Vector2(54, 10)], OUTLINE, 22)
	_stroke([Vector2(34, -7), Vector2(54, 10)], orange, 15)
	_draw_attack_effect(WHITE)


func _draw_fedora_boss() -> void:
	var blue := Color("#51a2da")
	_draw_feet(Color("#d8ecff"), 22)
	_ellipse(Vector2(0, 15), 57, 63, OUTLINE)
	_ellipse(Vector2(0, 12), 51, 57, Color("#1b456c"))
	_ellipse(Vector2(0, -68), 48, 47, OUTLINE)
	_ellipse(Vector2(0, -68), 43, 42, blue)
	# Fedora-inspired lowercase f / brim symbol.
	_poly([Vector2(-8, -94), Vector2(5, -94), Vector2(5, -79), Vector2(20, -79), Vector2(20, -68), Vector2(5, -68), Vector2(5, -43), Vector2(-8, -43), Vector2(-8, -68), Vector2(-20, -68), Vector2(-20, -79), Vector2(-8, -79)], WHITE)
	_stroke([Vector2(-34, -7), Vector2(-54, 10)], OUTLINE, 22)
	_stroke([Vector2(-34, -7), Vector2(-54, 10)], blue, 15)
	_stroke([Vector2(34, -7), Vector2(54, 10)], OUTLINE, 22)
	_stroke([Vector2(34, -7), Vector2(54, 10)], blue, 15)
	_draw_attack_effect(WHITE)


func _draw_debian_boss() -> void:
	var red := Color("#d70a53")
	_draw_feet(Color("#dceefa"), 22)
	_ellipse(Vector2(0, 15), 57, 63, OUTLINE)
	_ellipse(Vector2(0, 12), 51, 57, Color("#671b3a"))
	_ellipse(Vector2(0, -68), 48, 47, OUTLINE)
	_ellipse(Vector2(0, -68), 43, 42, red)
	# A bold curled Debian-inspired swirl mark.
	draw_arc(Vector2(0, -68), 23.0, -2.5, 2.2, 48, WHITE, 8.0, true)
	draw_arc(Vector2(5, -70), 12.0, -2.0, 2.4, 32, WHITE, 5.0, true)
	_ellipse(Vector2(17, -56), 5, 5, WHITE)
	_stroke([Vector2(-34, -7), Vector2(-54, 10)], OUTLINE, 22)
	_stroke([Vector2(-34, -7), Vector2(-54, 10)], red, 15)
	_stroke([Vector2(34, -7), Vector2(54, 10)], OUTLINE, 22)
	_stroke([Vector2(34, -7), Vector2(54, 10)], red, 15)
	_draw_attack_effect(WHITE)

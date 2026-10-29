extends Node2D
## Original vector mascots inspired by each project's familiar visual identity.
## Drawn in-engine so the game does not depend on external image assets.

@export var character_id := "tux"
@export var emblem_scale := 1.0

const INK := Color("#11131a")
const WHITE := Color("#fffaf0")
const TUX_BLACK := Color("#171c24")
const TUX_ORANGE := Color("#ff9f1c")
const GNU_FUR := Color("#9b785c")
const GNU_LIGHT := Color("#e8d9c5")
const GNU_DARK := Color("#4d3c31")
const BSD_RED := Color("#c92332")
const BSD_DARK := Color("#741725")
const BSD_CREAM := Color("#f5e8cf")
const PUFFY_YELLOW := Color("#ffdf32")
const PUFFY_BELLY := Color("#fff0c2")
const PUFFY_FIN := Color("#ffb91f")


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * emblem_scale)
	match character_id:
		"gnu":
			_draw_gnu()
		"beastie":
			_draw_beastie()
		"puffy":
			_draw_puffy()
		_:
			_draw_tux()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ellipse(center: Vector2, rx: float, ry: float, color: Color, steps: int = 32) -> void:
	var points := PackedVector2Array()
	for i in range(steps):
		var angle := TAU * float(i) / float(steps)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)


func _poly(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _line(points: Array[Vector2], color: Color, width: float) -> void:
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width, true)


func _eye(pos: Vector2, radius: float = 4.0) -> void:
	_ellipse(pos, radius + 1.5, radius + 1.5, INK)
	_ellipse(pos, radius, radius, WHITE)
	_ellipse(pos + Vector2(1.5, 0), radius * 0.42, radius * 0.65, INK)


func _draw_tux() -> void:
	# Classic round penguin silhouette, white belly, orange beak and feet.
	_line([Vector2(-15, 25), Vector2(-22, 34)], INK, 8)
	_line([Vector2(15, 25), Vector2(22, 34)], INK, 8)
	_line([Vector2(-15, 25), Vector2(-22, 34)], TUX_ORANGE, 5)
	_line([Vector2(15, 25), Vector2(22, 34)], TUX_ORANGE, 5)
	_poly([Vector2(-26, -2), Vector2(-43, 14), Vector2(-31, 20), Vector2(-20, 11)], INK)
	_poly([Vector2(26, -2), Vector2(43, 14), Vector2(31, 20), Vector2(20, 11)], INK)
	_ellipse(Vector2(0, 7), 30, 35, INK)
	_ellipse(Vector2(0, 12), 19, 25, WHITE)
	_ellipse(Vector2(0, -23), 29, 26, INK)
	_ellipse(Vector2(0, -11), 20, 16, WHITE)
	_eye(Vector2(-9, -25), 4.4)
	_eye(Vector2(9, -25), 4.4)
	_poly([Vector2(0, -20), Vector2(17, -15), Vector2(0, -10)], TUX_ORANGE)


func _draw_gnu() -> void:
	# GNU's familiar wildebeest head profile with long curved horns and mane.
	_line([Vector2(-15, -19), Vector2(-28, -31), Vector2(-38, -30), Vector2(-43, -20)], INK, 7)
	_line([Vector2(-15, -19), Vector2(-28, -31), Vector2(-38, -30), Vector2(-43, -20)], GNU_LIGHT, 4)
	_line([Vector2(9, -20), Vector2(19, -34), Vector2(31, -35), Vector2(37, -24)], INK, 7)
	_line([Vector2(9, -20), Vector2(19, -34), Vector2(31, -35), Vector2(37, -24)], GNU_LIGHT, 4)
	_poly([Vector2(-28, -15), Vector2(-17, -26), Vector2(5, -24), Vector2(21, -13), Vector2(27, 3), Vector2(13, 20), Vector2(-8, 19), Vector2(-22, 8)], INK)
	_poly([Vector2(-25, -15), Vector2(-15, -23), Vector2(4, -21), Vector2(18, -11), Vector2(23, 2), Vector2(11, 16), Vector2(-7, 15), Vector2(-19, 6)], GNU_FUR)
	_poly([Vector2(9, -6), Vector2(30, -5), Vector2(36, 5), Vector2(27, 16), Vector2(8, 13)], INK)
	_poly([Vector2(12, -4), Vector2(28, -3), Vector2(32, 5), Vector2(25, 11), Vector2(11, 9)], GNU_LIGHT)
	_poly([Vector2(-19, -8), Vector2(-8, -1), Vector2(-13, 13), Vector2(-24, 5)], GNU_DARK)
	_eye(Vector2(7, -13), 3.8)
	_ellipse(Vector2(29, 4), 2.5, 2, INK)


func _draw_beastie() -> void:
	# Red BSD daemon mascot with horns, pointed ears and its signature forked tail.
	_line([Vector2(-13, 20), Vector2(-26, 26), Vector2(-32, 17), Vector2(-27, 9)], INK, 5)
	_line([Vector2(-13, 20), Vector2(-26, 26), Vector2(-32, 17), Vector2(-27, 9)], BSD_RED, 3)
	_line([Vector2(-13, -20), Vector2(-23, -31), Vector2(-28, -22)], INK, 8)
	_line([Vector2(-13, -20), Vector2(-23, -31), Vector2(-28, -22)], BSD_RED, 5)
	_line([Vector2(13, -20), Vector2(23, -31), Vector2(28, -22)], INK, 8)
	_line([Vector2(13, -20), Vector2(23, -31), Vector2(28, -22)], BSD_RED, 5)
	_ellipse(Vector2(0, 4), 25, 29, INK)
	_ellipse(Vector2(0, 4), 21, 25, BSD_RED)
	_ellipse(Vector2(0, -15), 23, 19, INK)
	_ellipse(Vector2(0, -15), 19, 15, BSD_RED)
	_poly([Vector2(-17, -13), Vector2(-5, -10), Vector2(-10, -4)], BSD_CREAM)
	_poly([Vector2(17, -13), Vector2(5, -10), Vector2(10, -4)], BSD_CREAM)
	_ellipse(Vector2(-7, -16), 3, 4, WHITE)
	_ellipse(Vector2(7, -16), 3, 4, WHITE)
	_ellipse(Vector2(-6, -16), 1.4, 2.5, INK)
	_ellipse(Vector2(8, -16), 1.4, 2.5, INK)
	_line([Vector2(-7, -3), Vector2(0, 1), Vector2(7, -3)], INK, 2.5)
	# Tiny pitchfork motif above one shoulder.
	_line([Vector2(21, 15), Vector2(31, 26), Vector2(36, 21)], INK, 3)
	_line([Vector2(31, 26), Vector2(31, 15)], INK, 3)
	_line([Vector2(27, 16), Vector2(31, 21), Vector2(35, 16)], INK, 2)


func _draw_puffy() -> void:
	# OpenBSD-inspired bright yellow pufferfish, fins, tail, and dorsal spines.
	for i in range(9):
		var angle := PI + float(i) * PI / 8.0
		var inner := Vector2(cos(angle) * 23, sin(angle) * 26)
		var outer := Vector2(cos(angle) * 32, sin(angle) * 36)
		draw_line(inner, outer, INK, 5, true)
		draw_line(inner, outer, PUFFY_YELLOW, 3, true)
	for i in range(6):
		var angle := -0.2 + float(i) * PI / 6.0
		var inner := Vector2(cos(angle) * 23, sin(angle) * 25)
		var outer := Vector2(cos(angle) * 31, sin(angle) * 34)
		draw_line(inner, outer, INK, 4, true)
		draw_line(inner, outer, PUFFY_YELLOW, 2.5, true)
	_poly([Vector2(-22, 4), Vector2(-39, -5), Vector2(-38, 10), Vector2(-24, 15)], INK)
	_poly([Vector2(-23, 4), Vector2(-35, -2), Vector2(-34, 8), Vector2(-24, 12)], PUFFY_FIN)
	_poly([Vector2(-12, 20), Vector2(-20, 32), Vector2(-5, 27)], INK)
	_poly([Vector2(-11, 20), Vector2(-17, 28), Vector2(-7, 25)], PUFFY_FIN)
	_poly([Vector2(11, 20), Vector2(20, 32), Vector2(5, 27)], INK)
	_poly([Vector2(10, 20), Vector2(17, 28), Vector2(7, 25)], PUFFY_FIN)
	_ellipse(Vector2(0, 0), 27, 29, INK)
	_ellipse(Vector2(0, 0), 23, 25, PUFFY_YELLOW)
	_ellipse(Vector2(-2, 9), 15, 15, PUFFY_BELLY)
	_eye(Vector2(9, -7), 4.3)
	_ellipse(Vector2(18, 1), 3, 2, INK)
	_ellipse(Vector2(19, 0), 1.5, 1, Color("#ff9f9a"))

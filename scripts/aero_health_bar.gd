
extends Control
class_name AeroHealthBar

var fighter_label := "FIGHTER"
var current_health := 100
var maximum_health := 100
var player_side := 1

const GLASS_BLUE := Color("#a9e4ff")
const GLASS_EDGE := Color("#e5f7ff")
const GLASS_SHADOW := Color("#172f50")
const GLASS_DARK := Color("#101d35")
const GLASS_HIGHLIGHT := Color(0.82, 0.96, 1.0, 0.52)
const GLASS_REFLECTION := Color(1.0, 1.0, 1.0, 0.19)


func setup(label: String, side: int, max_hp: int = 100) -> void:
	fighter_label = label
	player_side = side
	maximum_health = maxi(1, max_hp)
	current_health = maximum_health
	queue_redraw()


func set_health(hp: int) -> void:
	current_health = clampi(hp, 0, maximum_health)
	queue_redraw()


func set_fighter_label(label: String) -> void:
	fighter_label = label
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	var ratio := clampf(
		float(current_health) / float(maximum_health),
		0.0,
		1.0
	)

	# Outer drop-shadow and dark glass backing.
	_rounded_rect(
		Rect2(2, 4, size.x - 4, size.y - 2),
		10.0,
		Color(0.0, 0.0, 0.0, 0.38)
	)

	_rounded_rect(
		bounds,
		10.0,
		GLASS_SHADOW
	)

	_rounded_rect(
		Rect2(2, 2, size.x - 4, size.y - 6),
		8.0,
		GLASS_DARK
	)

	# Recessed interior.
	var interior := Rect2(
		6,
		6,
		maxf(0.0, size.x - 12),
		maxf(0.0, size.y - 14)
	)

	_rounded_rect(
		interior,
		5.0,
		Color("#091321")
	)

	# Health fill with a color based on remaining HP.
	var inner_width := maxf(0.0, interior.size.x - 4.0)
	var fill_width := inner_width * ratio
	var fill_rect := Rect2(
		interior.position.x + 2.0,
		interior.position.y + 2.0,
		fill_width,
		maxf(0.0, interior.size.y - 4.0)
	)

	if fill_width > 0.0:
		var fill_color := _health_color(ratio)

		_rounded_rect(
			fill_rect,
			4.0,
			fill_color.darkened(0.18)
		)

		# Simulated gradient: multiple narrow colored strips.
		var segments := 20

		for i in range(segments):
			var start_x := float(i) / float(segments) * fill_width
			var end_x := float(i + 1) / float(segments) * fill_width
			var segment_width := end_x - start_x

			if segment_width <= 0.0:
				continue

			var blend := float(i) / float(maxi(1, segments - 1))
			var segment_color := fill_color.lerp(
				Color("#d9ffe0"),
				0.20 * (1.0 - blend)
			)

			draw_rect(
				Rect2(
					fill_rect.position.x + start_x,
					fill_rect.position.y + 1,
					segment_width + 0.5,
					maxf(0.0, fill_rect.size.y - 2)
				),
				segment_color
			)

		# Glossy top highlight over the filled portion.
		draw_rect(
			Rect2(
				fill_rect.position.x + 3,
				fill_rect.position.y + 1,
				maxf(0.0, fill_rect.size.x - 6),
				maxf(0.0, fill_rect.size.y * 0.30)
			),
			Color(1.0, 1.0, 1.0, 0.24)
		)

	# Vista-style translucent reflection across the full glass.
	_rounded_rect(
		Rect2(3, 3, size.x - 6, maxf(1.0, size.y * 0.38)),
		7.0,
		GLASS_REFLECTION
	)

	# Thin luminous top edge.
	draw_line(
		Vector2(12, 3),
		Vector2(size.x - 12, 3),
		GLASS_HIGHLIGHT,
		1.5,
		true
	)

	# Bright outer rim and subtle bottom edge.
	_draw_rounded_outline(
		Rect2(1, 1, size.x - 2, size.y - 4),
		10.0,
		GLASS_EDGE,
		1.4
	)

	draw_line(
		Vector2(12, size.y - 4),
		Vector2(size.x - 12, size.y - 4),
		Color(0.25, 0.53, 0.78, 0.65),
		1.0,
		true
	)

	# Small blue glass glints at the corners.
	draw_line(
		Vector2(8, 8),
		Vector2(23, 8),
		Color(1.0, 1.0, 1.0, 0.6),
		1.2,
		true
	)

	draw_line(
		Vector2(size.x - 23, 8),
		Vector2(size.x - 8, 8),
		Color(1.0, 1.0, 1.0, 0.6),
		1.2,
		true
	)

	# Readable text over the glass.
	var font := ThemeDB.fallback_font
	var hp_text := "%s   %d / %d HP" % [
		fighter_label.to_upper(),
		current_health,
		maximum_health
	]

	var font_size := 15
	var text_width := font.get_string_size(
		hp_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x

	var text_x := (size.x - text_width) * 0.5
	var text_y := size.y * 0.69

	# Dark text shadow helps against bright green health.
	draw_string(
		font,
		Vector2(text_x + 1, text_y + 1),
		hp_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.0, 0.0, 0.0, 0.85)
	)

	draw_string(
		font,
		Vector2(text_x, text_y),
		hp_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color("#ffffff")
	)


func _health_color(ratio: float) -> Color:
	if ratio >= 0.5:
		var amount := (ratio - 0.5) / 0.5

		return Color("#b6ff8a").lerp(
			Color("#28d96a"),
			amount
		)

	var amount := ratio / 0.5

	return Color("#ff334f").lerp(
		Color("#ffdb50"),
		amount
	)


func _rounded_rect(
	rect: Rect2,
	radius: float,
	color: Color
) -> void:
	var points := _rounded_points(rect, radius)
	draw_colored_polygon(PackedVector2Array(points), color)


func _draw_rounded_outline(
	rect: Rect2,
	radius: float,
	color: Color,
	line_width: float
) -> void:
	var points := _rounded_points(rect, radius)

	for i in range(points.size()):
		var next_index := (i + 1) % points.size()

		draw_line(
			points[i],
			points[next_index],
			color,
			line_width,
			true
		)


func _rounded_points(rect: Rect2, radius: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var r := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	var corners := [
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r),
		Vector2(rect.position.x + r, rect.position.y + rect.size.y - r),
		Vector2(rect.position.x + r, rect.position.y + r)
	]

	var angle_starts := [-90.0, 0.0, 90.0, 180.0]

	for corner_index in range(4):
		for step in range(5):
			var angle := deg_to_rad(
				angle_starts[corner_index] + float(step) * 90.0 / 4.0
			)

			points.append(
				corners[corner_index]
				+ Vector2(cos(angle), sin(angle)) * r
			)

	return points

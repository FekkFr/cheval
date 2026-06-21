extends HSlider

# Graine fixe par slider pour que le gribouillis reste stable tant que la valeur ne change pas
var _sketch_seed = 0

func _ready():
	_sketch_seed = randi()
	add_theme_stylebox_override("slider", StyleBoxEmpty.new())
	add_theme_stylebox_override("grabber_area", StyleBoxEmpty.new())
	add_theme_stylebox_override("grabber_area_highlight", StyleBoxEmpty.new())

	# Masque complètement l'icône native du curseur (le rond blanc par défaut)
	var empty_icon = ImageTexture.new()
	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	empty_icon.set_image(img)
	add_theme_icon_override("grabber", empty_icon)
	add_theme_icon_override("grabber_highlight", empty_icon)
	add_theme_icon_override("grabber_disabled", empty_icon)

	queue_redraw()
	value_changed.connect(func(_v): queue_redraw())

func _draw():
	var track_y = size.y / 2.0
	var ratio = (value - min_value) / (max_value - min_value)
	var filled_x = ratio * size.x

	seed(_sketch_seed)  # même tirage à chaque redraw tant que la seed ne change pas

	# Toute la piste en gribouillis (fond, sur toute la largeur) — gris crayon à papier
	_draw_sketchy_track(Vector2(0, track_y), size.x, Color(0.55, 0.55, 0.55, 0.5), 2.0, 3)

	seed(_sketch_seed)  # reset pour que la partie remplie démarre avec le même motif de base
	# Partie remplie, par-dessus, plus marquée
	if filled_x > 2.0:
		_draw_sketchy_track(Vector2(0, track_y), filled_x, Color("#0a0705"), 3.0, 4)

	seed(_sketch_seed + 1)
	_draw_sketchy_circle(Vector2(filled_x, track_y), 7.0, Color("#0a0705"))

# Dessine une ligne "crayonnée" composée de plusieurs petits segments tremblés,
# avec quelques passes superposées comme un vrai coup de crayon répété.
func _draw_sketchy_track(start: Vector2, length: float, color: Color, width: float, passes: int):
	if length < 1.0:
		return
	var num_segments = max(int(length / 8.0), 4)

	for p in passes:
		var points = []
		for i in num_segments + 1:
			var t = float(i) / float(num_segments)
			var x = start.x + t * length
			var jitter = randf_range(-1.6, 1.6)
			points.append(Vector2(x, start.y + jitter))

		var line_color = color
		if p > 0:
			line_color = color * Color(1, 1, 1, 0.45)  # passes supplémentaires plus légères

		for i in points.size() - 1:
			draw_line(points[i], points[i + 1], line_color, width * (1.0 if p == 0 else 0.6))

func _draw_sketchy_circle(center: Vector2, radius: float, color: Color):
	var points = []
	var num_points = 10
	for i in num_points + 1:
		var angle = (TAU / num_points) * i
		var r = radius + randf_range(-1.0, 1.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	for i in points.size() - 1:
		draw_line(points[i], points[i + 1], color, 2.0)

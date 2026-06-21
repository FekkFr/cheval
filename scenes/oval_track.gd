class_name OvalTrack
extends Node2D

var path_follows = [null, null, null, null]
var lane_paths = []

var _race_active = false
var _race_elapsed = 0.0
var _race_duration = 8.0
var _race_control_points = []

func _ready():
	_generate_stadium_lanes()
	_create_horse_followers()

# ── Génère 4 couloirs concentriques en forme de stade ──
func _generate_stadium_lanes():
	var center = Vector2(400, 300)
	var straight_length = 300.0
	var base_radius_y = 120.0
	var lane_spacing = 25.0
	var arc_points = 24

	for lane_idx in 4:
		var radius_y = base_radius_y + (lane_idx * lane_spacing)
		var half_straight = straight_length / 2.0

		var points = PackedVector2Array()

		points.append(center + Vector2(half_straight, -radius_y))
		points.append(center + Vector2(-half_straight, -radius_y))

		var left_center = center + Vector2(-half_straight, 0)
		for i in range(1, arc_points):
			var t = float(i) / float(arc_points)
			var angle = deg_to_rad(-90.0) - t * PI
			var pos = left_center + Vector2(cos(angle), sin(angle)) * radius_y
			points.append(pos)

		points.append(center + Vector2(-half_straight, radius_y))
		points.append(center + Vector2(half_straight, radius_y))

		var right_center = center + Vector2(half_straight, 0)
		for i in range(1, arc_points):
			var t = float(i) / float(arc_points)
			var angle = deg_to_rad(90.0) - t * PI
			var pos = right_center + Vector2(cos(angle), sin(angle)) * radius_y
			points.append(pos)

		points.reverse()
		points.append(points[0])

		var new_curve = Curve2D.new()
		for p in points:
			new_curve.add_point(p)

		var lane_path = Path2D.new()
		lane_path.curve = new_curve
		add_child(lane_path)
		lane_paths.append(lane_path)

		_draw_dashed_line(points)

# ── Dessine une ligne en pointillés à partir d'une liste de points ──
func _draw_dashed_line(points: PackedVector2Array):
	var dash_length = 10.0
	var gap_length = 7.0
	var dash_dist = 0.0
	var drawing = true

	for i in points.size() - 1:
		var start = points[i]
		var end = points[i + 1]
		var segment_length = start.distance_to(end)
		if segment_length < 0.01:
			continue

		var dir = (end - start).normalized()
		var pos = 0.0

		while pos < segment_length:
			var step = (dash_length - dash_dist) if drawing else (gap_length - dash_dist)
			step = min(step, segment_length - pos)

			if drawing and step > 0.1:
				var seg_start = start + dir * pos
				var seg_end = start + dir * (pos + step)
				var dash = Line2D.new()
				dash.add_point(seg_start)
				dash.add_point(seg_end)
				dash.width = 3.0
				dash.default_color = Color("#0a0a0a")
				dash.antialiased = true
				add_child(dash)

			pos += step
			dash_dist += step

			if (drawing and dash_dist >= dash_length) or (not drawing and dash_dist >= gap_length):
				dash_dist = 0.0
				drawing = !drawing

# ── Crée les 4 chevaux (PathFollow2D + Sprite2D) sur leur couloir respectif ──
func _create_horse_followers():
	var colors = [Color("#c8860a"), Color("#8b1a1a"), Color("#4a9a4a"), Color("#7aacc8")]

	for lane_idx in 4:
		var pf = PathFollow2D.new()
		pf.rotates = false
		pf.loop = true
		lane_paths[lane_idx].add_child(pf)
		path_follows[lane_idx] = pf

		var sprite = Sprite2D.new()
		sprite.texture = load("res://assets/2d/horse.png")
		sprite.scale = Vector2(2.0, 2.0)
		sprite.modulate = colors[lane_idx]
		pf.add_child(sprite)

# ── Anime la course avec suspense (résultat connu mais parcours imprévisible) ──
func animate_race(scores: Array):
	var duration = 8.0
	var max_score = float(scores.max())

	var final_ratios = []
	for s in scores:
		final_ratios.append(float(s) / max_score)

	var dramatic_race = randf() < 0.33
	var dramatic_horse_idx = -1
	if dramatic_race:
		var candidates = []
		for i in final_ratios.size():
			if final_ratios[i] < 1.0:
				candidates.append(i)
		if candidates.size() > 0:
			dramatic_horse_idx = candidates[randi() % candidates.size()]

	var control_points_per_horse = []
	for i in path_follows.size():
		var is_dramatic = (i == dramatic_horse_idx)
		control_points_per_horse.append(_build_control_points(final_ratios[i], is_dramatic))

	_race_active = true
	_race_elapsed = 0.0
	_race_duration = duration
	_race_control_points = control_points_per_horse

	await get_tree().create_timer(duration + 0.3).timeout
	_race_active = false

	for i in path_follows.size():
		path_follows[i].progress_ratio = final_ratios[i]

# ── Génère des points de contrôle (t, ratio) STRICTEMENT croissants en t ET en ratio,
# pour garantir une spline Catmull-Rom sans aucun overshoot négatif (donc sans blocage visuel). ──
func _build_control_points(final_ratio: float, is_dramatic: bool) -> Array:
	var points = [Vector2(0.0, 0.0)]
	var num_mid_points = 6

	# On répartit le bruit comme des "vitesses" relatives entre checkpoints,
	# jamais comme un delta qui pourrait reculer.
	var raw_steps = []
	for i in num_mid_points + 1:
		var t = float(i + 1) / float(num_mid_points + 1)
		var weight = 1.0

		if is_dramatic:
			# Vitesse très lente au début (cheval qui traîne), puis très rapide à la fin (remontée)
			var slow_phase = 1.0 - t
			weight = lerp(0.25, 1.8, 1.0 - slow_phase) + randf_range(-0.15, 0.15)
		else:
			# Petites variations de vitesse, jamais drastiques (course serrée)
			weight = 1.0 + randf_range(-0.18, 0.18)

		weight = max(weight, 0.05)  # jamais totalement à l'arrêt
		raw_steps.append(weight)

	var total_weight = 0.0
	for w in raw_steps:
		total_weight += w

	var cumulative = 0.0
	for i in raw_steps.size():
		cumulative += raw_steps[i]
		var t = float(i + 1) / float(num_mid_points + 1)
		var ratio = (cumulative / total_weight) * final_ratio
		points.append(Vector2(t, ratio))

	# Forcer le tout dernier point pile sur le ratio final exact
	points[points.size() - 1] = Vector2(1.0, final_ratio)
	return points

# ── Évalue la position interpolée (Catmull-Rom) à un instant t pour un cheval donné ──
func _evaluate_spline(points: Array, t: float) -> float:
	t = clampf(t, 0.0, 1.0)

	var seg_idx = 0
	for i in points.size() - 1:
		if t >= points[i].x and t <= points[i + 1].x:
			seg_idx = i
			break
		seg_idx = i

	var p1 = points[seg_idx]
	var p2 = points[min(seg_idx + 1, points.size() - 1)]
	var p0 = points[max(seg_idx - 1, 0)]
	var p3 = points[min(seg_idx + 2, points.size() - 1)]

	var seg_length = p2.x - p1.x
	var local_t = 0.0
	if seg_length > 0.0001:
		local_t = (t - p1.x) / seg_length

	var t2 = local_t * local_t
	var t3 = t2 * local_t
	var y = 0.5 * (
		(2.0 * p1.y) +
		(-p0.y + p2.y) * local_t +
		(2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
		(-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3
	)
	return clampf(y, 0.0, 1.0)

func _process(delta):
	if not _race_active:
		return
	_race_elapsed += delta
	var t = clampf(_race_elapsed / _race_duration, 0.0, 1.0)

	for i in path_follows.size():
		var ratio = _evaluate_spline(_race_control_points[i], t)
		path_follows[i].progress_ratio = ratio

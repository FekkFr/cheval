extends Control

func _draw():
	var rect = Rect2(Vector2.ZERO, size)
	_draw_dashed_rect(rect, 6.0, 4.0, Color("#020100ff"), 2.0)

func _draw_dashed_rect(rect: Rect2, dash: float, gap: float, color: Color, width: float):
	var corners = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]
	for i in 4:
		_draw_dashed_segment(corners[i], corners[(i + 1) % 4], dash, gap, color, width)

func _draw_dashed_segment(start: Vector2, end: Vector2, dash: float, gap: float, color: Color, width: float):
	var length = start.distance_to(end)
	if length < 0.01:
		return
	var dir = (end - start).normalized()
	var pos = 0.0
	var drawing = true

	while pos < length:
		var step = min(dash if drawing else gap, length - pos)
		if drawing:
			draw_line(start + dir * pos, start + dir * (pos + step), color, width)
		pos += step
		drawing = !drawing

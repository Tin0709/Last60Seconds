extends Control

# Each character is one pixel, drawn at an integer scale for crisp heart icons.
const HEART = [
	".##.##.",
	"#######",
	"#######",
	"#######",
	".#####.",
	"..###..",
	"...#...",
]

var health: int = 5:
	set(value):
		health = value
		queue_redraw()

func _draw() -> void:
	draw_style_box(get_theme_stylebox("normal", "Label"), Rect2(Vector2.ZERO, size))
	for index in range(5):
		var filled = index < health
		var origin = Vector2(18 + index * 40, 8)
		for y in range(HEART.size()):
			for x in range(HEART[y].length()):
				if HEART[y][x] != "#":
					continue
				var color = Color("e85962") if filled else Color("384133")
				if y >= 4:
					color = Color("ac354b") if filled else Color("293126")
				elif y == 1 and x in [1, 4] and filled:
					color = Color("ffb6a3")
				draw_rect(Rect2(origin + Vector2(x, y) * 4 + Vector2(0, 4), Vector2(4, 4)), Color("171e16"))
				draw_rect(Rect2(origin + Vector2(x, y) * 4, Vector2(4, 4)), color)

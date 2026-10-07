@tool
class_name RoomBackdrop
extends Node2D

@export var room_width: float = 1280.0
@export var tree_spacing: float = 165.0
@export var tree_offset: float = 55.0
@export var canopy_tint: Color = Color(0.30, 0.46, 0.49, 0.65)
@export var trunk_tint: Color = Color(0.28, 0.42, 0.47, 0.8)
@export var fog_amount: int = 50
@export var sky_top: Color = Color("10192a")
@export var sky_bottom: Color = Color("172b3d")
@export var platform_tint: Color = Color("71655e")
@export var lantern_tint: Color = Color("f1dba6")
@export var lantern_spacing: float = 260.0

var platforms: Array[Rect2] = []
var solids: Array[Rect2] = []
var lanterns: Array[float] = []
var elapsed: float = 0.0
var theme: Color = Color("8bcfbe")
@onready var terrain: RoomTerrain = $Terrain


func configure(width: float, room_platforms: Array[Rect2], room_solids: Array[Rect2], room_theme: Color) -> void:
	room_width = width
	platforms = room_platforms
	solids = room_solids
	theme = room_theme
	lanterns.clear()
	for x in range(120, int(room_width), int(lantern_spacing)):
		lanterns.append(float(x))
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint() and platforms.is_empty():
		_collect_editor_geometry()
	if solids.is_empty():
		solids.append(Rect2(0, 610, room_width, 210))
	draw_rect(Rect2(-640, -600, room_width + 1280, 1700), sky_top)
	for band in range(6):
		var t: float = float(band) / 5.0
		draw_rect(Rect2(-640, 60 + band * 95, room_width + 1280, 100), sky_top.lerp(sky_bottom, t))
	for i in range(28):
		var star_x: float = fposmod(i * 197.0 + 31.0, room_width)
		var star_y: float = 92.0 + fposmod(i * 83.0, 255.0)
		var twinkle: float = 0.24 + 0.18 * sin(elapsed * 0.8 + i * 1.7)
		draw_circle(Vector2(star_x, star_y), 1.2 if i % 4 else 1.8, Color(0.78, 0.87, 0.87, twinkle))
	draw_circle(Vector2(room_width - 330, 155), 64, Color("d7dfc6"))
	draw_circle(Vector2(room_width - 304, 137), 60, sky_top)
	for i in range(-1, int(room_width / 90) + 2):
		var x: float = float(i * 90)
		var h: float = 160.0 + fposmod(i * 71, 190)
		draw_rect(Rect2(x, 610 - h, 12, h), Color("182e3c"))
		draw_line(Vector2(x + 6, 610 - h), Vector2(x - 40, 610 - h + 55), Color("182e3c"), 10)
		draw_line(Vector2(x + 6, 610 - h + 65), Vector2(x + 42, 610 - h + 20), Color("182e3c"), 8)
	for i in range(0, int(room_width / tree_spacing) + 1):
		var x: float = float(i * tree_spacing + tree_offset)
		draw_line(Vector2(x, 610), Vector2(x - 12, 145), Color("203e46"), 7)
		for y in range(210, 570, 74):
			draw_line(Vector2(x - 16, y), Vector2(x + 8, y), Color("365351"), 2)
			draw_line(Vector2(x - 5, y), Vector2(x + 35, y - 18), Color("28474b"), 4)
	for i in range(fog_amount):
		var fog_x: float = fposmod(i * 143.0 + sin(elapsed * 0.15 + i) * 12, room_width)
		var fog_y: float = 150.0 + fposmod(i * 67.0, 400.0)
		draw_circle(Vector2(fog_x, fog_y), 1.5, Color(theme, 0.25 + 0.2 * sin(elapsed + i)))
	if is_instance_valid(terrain):
		terrain.configure(solids, platforms)
	for x in lanterns:
		draw_line(Vector2(x, 610), Vector2(x, 549), Color("545058"), 3)
		draw_rect(Rect2(x - 7, 545, 14, 21), Color("b39e71"))
		draw_rect(Rect2(x - 5, 549, 10, 13), lantern_tint)
		draw_circle(Vector2(x, 555), 19, Color(0.9, 0.7, 0.4, 0.04))

func _collect_editor_geometry() -> void:
	var parent: Node = get_parent()
	if not is_instance_valid(parent):
		return
	for body in parent.get_children():
		if not body is StaticBody2D:
			continue
		for shape_node in body.get_children():
			if not shape_node is CollisionShape2D or shape_node.shape == null:
				continue
			var rect: Rect2 = Rect2(body.position + shape_node.position + shape_node.shape.get_rect().position, shape_node.shape.get_rect().size)
			if body.collision_layer == 256:
				platforms.append(rect)
			else:
				solids.append(rect)

@tool
class_name RoomTerrain
extends Node2D

@export var skin: TerrainSkin
var solids: Array[Rect2] = []
var platforms: Array[Rect2] = []

func _ready() -> void:
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	# Inspector edits to the shared skin are immediately visible in the editor.
	queue_redraw()

func configure(new_solids: Array[Rect2], new_platforms: Array[Rect2]) -> void:
	if solids == new_solids and platforms == new_platforms:
		return
	solids = new_solids.duplicate()
	platforms = new_platforms.duplicate()
	queue_redraw()

func _draw() -> void:
	if skin == null or skin.texture == null:
		return
	for rect: Rect2 in solids:
		if rect.position.y >= 0.0:
			_draw_surface(rect, false)
	for rect: Rect2 in platforms:
		_draw_surface(rect, true)

func _draw_surface(rect: Rect2, thin: bool) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var height: float = minf(skin.surface_height, rect.size.y + skin.grass_above_surface)
	if thin:
		height = minf(height, skin.platform_depth + skin.grass_above_surface)
	var top: float = rect.position.y - skin.grass_above_surface
	# Deep soil is continuous; only the outermost ends receive cliff caps.
	if not thin and rect.end.y > top + height:
		draw_rect(Rect2(rect.position.x, top + height - 2.0, rect.size.x, rect.end.y - top - height + 2.0), skin.soil_color)
	var cap_width: float = minf(skin.repeat_width, rect.size.x * 0.5)
	_draw_piece(Rect2(rect.position.x, top, cap_width, height), skin.left_region, cap_width / skin.repeat_width, height / skin.surface_height, false)
	var x: float = rect.position.x + cap_width
	var middle_end: float = rect.end.x - cap_width
	while x < middle_end - 0.01:
		var width: float = minf(skin.repeat_width, middle_end - x)
		_draw_piece(Rect2(x, top, width, height), skin.middle_region, width / skin.repeat_width, height / skin.surface_height, false)
		x += width
	_draw_piece(Rect2(middle_end, top, cap_width, height), skin.right_region, cap_width / skin.repeat_width, height / skin.surface_height, true)

func _draw_piece(destination: Rect2, region: Rect2, width_ratio: float, height_ratio: float, right_cap: bool) -> void:
	var source: Rect2 = region
	source.size *= Vector2(width_ratio, height_ratio)
	if right_cap:
		source.position.x = region.end.x - source.size.x
	draw_texture_rect_region(skin.texture, destination, source)

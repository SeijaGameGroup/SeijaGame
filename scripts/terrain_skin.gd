@tool
class_name TerrainSkin
extends Resource

@export var texture: Texture2D
@export_group("Source slices (pixels)")
@export var left_region: Rect2 = Rect2(0, 88, 724, 520)
@export var middle_region: Rect2 = Rect2(724, 88, 724, 520)
@export var right_region: Rect2 = Rect2(1448, 88, 724, 520)
@export_group("World size")
@export_range(16.0, 256.0, 1.0) var repeat_width: float = 128.0
@export_range(16.0, 256.0, 1.0) var surface_height: float = 96.0
@export_range(0.0, 48.0, 1.0) var grass_above_surface: float = 12.0
@export_range(8.0, 64.0, 1.0) var platform_depth: float = 24.0
@export var soil_color: Color = Color("182332")

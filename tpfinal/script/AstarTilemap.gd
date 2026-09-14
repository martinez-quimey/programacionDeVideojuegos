class_name PathfindAstar extends TileMapLayer

## Generic 2D A* (AStar) graph pathfinding solution.
##
## it uses a TileMapLayer as a visual guide to "paint" each node tile.
## It only uses the cell with id 0 as guide for the nodes designation.

## Determines how the nodes are linked, either horizontal only or
## horizontal and diagonal
@export_enum("Horizontals Only", "Horizontals & Diagonals") var connection_type: int

# You can only create an AStar node from code, not from the Scene tab
@onready var _astar_object: AStar2D = AStar2D.new()
@onready var _map_limits: Rect2i = get_used_rect()

# get_used_cells_by_id is a method from the TileMapLayer node
# here the id 0 corresponds to the grey tile, the obstacles
@onready var _painted_walkable_cells: Array[Vector2i] = get_used_cells_by_id(0)
@onready var _half_cell_size: Vector2 = tile_set.tile_size / 2.0


## Returns if a given point in global coordinates corresponds to a
## given node inside the graph.
func is_valid_point(point: Vector2) -> bool:
	return _astar_object.has_point(
		_calculate_point_index(
			local_to_map(
				to_local(point)
			)
		)
	)


## Returns a path as a list of points between the closest starting point
## and the closest end point.
func get_simple_path(world_start: Vector2, world_end: Vector2) -> PackedVector2Array:
	var local_start_position: Vector2i = local_to_map(to_local(world_start))
	var local_end_position: Vector2i = local_to_map(to_local(world_end))
	
	var closest_start_point: int = _astar_object.get_closest_point(local_start_position)
	var closest_end_point: int = _astar_object.get_closest_point(local_end_position)
	if closest_start_point == -1 or closest_end_point == -1:
		return PackedVector2Array()
	
	var point_path: PackedVector2Array = _astar_object.get_point_path(
		closest_start_point,
		closest_end_point
	)
	
	var path_world: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in point_path:
		var point_world: Vector2 = to_global(
			Vector2(
				to_global(map_to_local(point))
			) + _half_cell_size
		)
		path_world.append(point_world)
	return path_world


func _ready():
	_astar_add_walkable_cells(_painted_walkable_cells)
	if connection_type:
		_astar_connect_walkable_cells_diagonal(_painted_walkable_cells)
	else:
		_astar_connect_walkable_cells(_painted_walkable_cells)
	hide()


# Loops through all cells within the map's bounds and
# adds all points to the _astar_object, except the obstacles
func _astar_add_walkable_cells(walkable_cells: Array[Vector2i]) -> void:
	for point: Vector2i in walkable_cells:
		# The AStar class references points with indices
		# Using a function to calculate the index from a point's coordinates
		# ensures we always get the same index with the same input point
		var point_index: int = _calculate_point_index(point)
		_astar_object.add_point(point_index, point)


# Once you added all points to the AStar node, you've got to connect them
# The points don't have to be on a grid: you can use this class
# to create walkable graphs however you'd like
# It's a little harder to code at first, but works for 2d, 3d,
# orthogonal grids, hex grids, tower defense games...
func _astar_connect_walkable_cells(points_array: Array[Vector2i]) -> void:
	for point: Vector2i in points_array:
		var point_index: int = _calculate_point_index(point)
		# For every cell in the map, we check the one to the top, right.
		# left and bottom of it. If it's in the map and not an obstacle,
		# We connect the current point with it
		var points_relative: Array[Vector2i] = [
			Vector2i(point.x + 1, point.y),
			Vector2i(point.x - 1, point.y),
			Vector2i(point.x, point.y + 1),
			Vector2i(point.x, point.y - 1)]
		for point_relative: Vector2i in points_relative:
			var point_relative_index: int = _calculate_point_index(point_relative)
			if not _astar_object.has_point(point_relative_index):
				continue
			# Note the 3rd argument. It tells the _astar_object that we want the
			# connection to be bilateral: from point A to B and B to A
			# If you set this value to false, it becomes a one-way path
			# As we loop through all points we can set it to false
			_astar_object.connect_points(point_index, point_relative_index, false)


# This is a variation of the method above
# It connects cells horizontally, vertically AND diagonally
func _astar_connect_walkable_cells_diagonal(points_array: Array[Vector2i]) -> void:
	for point: Vector2i in points_array:
		var point_index: int = _calculate_point_index(point)
		for local_y: int in range(3):
			for local_x: int in range(3):
				var point_relative: Vector2i = Vector2i(
					point.x + local_x - 1,
					point.y + local_y - 1
				)
				var point_relative_index: int = _calculate_point_index(point_relative)
				if (
					point_relative == point or
					not _astar_object.has_point(point_relative_index)
				):
					continue
				_astar_object.connect_points(point_index, point_relative_index, false)


# Calculates the unique ID of a given point inside the graph
func _calculate_point_index(point: Vector2i) -> int:
	var relative_point: Vector2i = point - _map_limits.position
	return int(relative_point.y * _map_limits.size.x + relative_point.x)

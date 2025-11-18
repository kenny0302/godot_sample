extends Node

# 路径追踪系统 - 记录玩家走过的路径
var visited_cells: Dictionary = {}
var maze_generator: Node3D
var last_grid_pos: Vector2i = Vector2i(-1, -1)

# 用于小地图显示
signal path_updated(visited_cells)

func _ready():
	maze_generator = get_parent().get_node("MazeGenerator")

func update_player_position(world_pos: Vector3):
	if not maze_generator:
		return

	var grid_pos = maze_generator.world_to_grid(world_pos)

	# 如果进入新的格子，标记为已访问
	if grid_pos != last_grid_pos:
		if maze_generator.is_valid_position(grid_pos):
			if not visited_cells.has(grid_pos):
				visited_cells[grid_pos] = true
				path_updated.emit(visited_cells)
			last_grid_pos = grid_pos

func is_cell_visited(grid_pos: Vector2i) -> bool:
	return visited_cells.has(grid_pos)

func get_visited_cells() -> Dictionary:
	return visited_cells

extends Node3D

# 迷宫生成器 - 使用递归回溯算法
@export var maze_width: int = 15
@export var maze_height: int = 15
@export var cell_size: float = 4.0
@export var wall_height: float = 3.0

var maze: Array = []
var visited: Array = []

# 存储迷宫信息供其他脚本使用
var start_position: Vector3
var exit_position: Vector3

func _ready():
	randomize()
	generate_maze()
	build_maze_3d()

# 生成迷宫逻辑
func generate_maze():
	# 初始化迷宫网格
	maze = []
	visited = []
	for y in range(maze_height):
		maze.append([])
		visited.append([])
		for x in range(maze_width):
			# 0=未访问, 1=路径, 墙壁通过相邻格子来表示
			maze[y].append({
				"visited": false,
				"walls": {"north": true, "south": true, "east": true, "west": true}
			})
			visited[y].append(false)

	# 使用递归回溯算法生成迷宫
	_carve_path(0, 0)

	# 设置起点和终点
	start_position = Vector3(0.5 * cell_size, 0, 0.5 * cell_size)
	exit_position = Vector3((maze_width - 0.5) * cell_size, 0, (maze_height - 0.5) * cell_size)

# 递归回溯算法
func _carve_path(x: int, y: int):
	maze[y][x]["visited"] = true

	# 获取未访问的邻居
	var directions = [
		{"name": "north", "dx": 0, "dy": -1},
		{"name": "south", "dx": 0, "dy": 1},
		{"name": "east", "dx": 1, "dy": 0},
		{"name": "west", "dx": -1, "dy": 0}
	]
	directions.shuffle()

	for dir in directions:
		var nx = x + dir["dx"]
		var ny = y + dir["dy"]

		if nx >= 0 and nx < maze_width and ny >= 0 and ny < maze_height:
			if not maze[ny][nx]["visited"]:
				# 移除墙壁
				maze[y][x]["walls"][dir["name"]] = false
				var opposite = _get_opposite_direction(dir["name"])
				maze[ny][nx]["walls"][opposite] = false

				# 递归访问
				_carve_path(nx, ny)

func _get_opposite_direction(direction: String) -> String:
	match direction:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
	return ""

# 构建3D迷宫
func build_maze_3d():
	# 创建墙壁材质
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.4, 0.4, 0.4)

	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.3, 0.3, 0.35)

	var exit_material = StandardMaterial3D.new()
	exit_material.albedo_color = Color(0.2, 1.0, 0.2)
	exit_material.emission_enabled = true
	exit_material.emission = Color(0.2, 1.0, 0.2)
	exit_material.emission_energy_multiplier = 0.5

	# 创建地板
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(maze_width * cell_size, 0.2, maze_height * cell_size)
	var floor_instance = MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.material_override = floor_material
	floor_instance.position = Vector3(maze_width * cell_size / 2.0, -0.1, maze_height * cell_size / 2.0)
	add_child(floor_instance)

	# 添加碰撞
	var floor_collision = StaticBody3D.new()
	var floor_collision_shape = CollisionShape3D.new()
	var floor_shape = BoxShape3D.new()
	floor_shape.size = floor_mesh.size
	floor_collision_shape.shape = floor_shape
	floor_collision.add_child(floor_collision_shape)
	floor_instance.add_child(floor_collision)

	# 创建外墙
	_create_outer_walls(wall_material)

	# 创建内部墙壁
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = Vector3(cell_size, wall_height, 0.2)

	for y in range(maze_height):
		for x in range(maze_width):
			var cell = maze[y][x]
			var pos = Vector3((x + 0.5) * cell_size, wall_height / 2.0, (y + 0.5) * cell_size)

			# 南墙
			if cell["walls"]["south"] and y < maze_height - 1:
				_create_wall(pos + Vector3(0, 0, cell_size / 2.0), Vector3(cell_size, wall_height, 0.2), wall_material)

			# 东墙
			if cell["walls"]["east"] and x < maze_width - 1:
				_create_wall(pos + Vector3(cell_size / 2.0, 0, 0), Vector3(0.2, wall_height, cell_size), wall_material)

	# 创建出口标记
	var exit_marker = MeshInstance3D.new()
	var exit_mesh = BoxMesh.new()
	exit_mesh.size = Vector3(1.5, 0.3, 1.5)
	exit_marker.mesh = exit_mesh
	exit_marker.material_override = exit_material
	exit_marker.position = exit_position + Vector3(0, 0.2, 0)
	add_child(exit_marker)

	# 添加出口触发区域
	var exit_area = Area3D.new()
	exit_area.name = "ExitArea"
	var exit_collision = CollisionShape3D.new()
	var exit_shape = BoxShape3D.new()
	exit_shape.size = Vector3(2.0, 2.0, 2.0)
	exit_collision.shape = exit_shape
	exit_area.add_child(exit_collision)
	exit_marker.add_child(exit_area)

func _create_outer_walls(material: StandardMaterial3D):
	# 北墙
	_create_wall(Vector3(maze_width * cell_size / 2.0, wall_height / 2.0, 0),
				 Vector3(maze_width * cell_size, wall_height, 0.2), material)
	# 南墙
	_create_wall(Vector3(maze_width * cell_size / 2.0, wall_height / 2.0, maze_height * cell_size),
				 Vector3(maze_width * cell_size, wall_height, 0.2), material)
	# 西墙
	_create_wall(Vector3(0, wall_height / 2.0, maze_height * cell_size / 2.0),
				 Vector3(0.2, wall_height, maze_height * cell_size), material)
	# 东墙
	_create_wall(Vector3(maze_width * cell_size, wall_height / 2.0, maze_height * cell_size / 2.0),
				 Vector3(0.2, wall_height, maze_height * cell_size), material)

func _create_wall(position: Vector3, size: Vector3, material: StandardMaterial3D):
	var wall_instance = MeshInstance3D.new()
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = size
	wall_instance.mesh = wall_mesh
	wall_instance.material_override = material
	wall_instance.position = position

	# 添加碰撞
	var wall_collision = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision_shape.shape = shape
	wall_collision.add_child(collision_shape)
	wall_instance.add_child(wall_collision)

	add_child(wall_instance)

# 获取网格坐标
func world_to_grid(world_pos: Vector3) -> Vector2i:
	var x = int(world_pos.x / cell_size)
	var z = int(world_pos.z / cell_size)
	return Vector2i(x, z)

# 检查位置是否有效
func is_valid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < maze_width and grid_pos.y >= 0 and grid_pos.y < maze_height

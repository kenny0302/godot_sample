extends Control

# 小地图UI系统
@export var cell_pixel_size: int = 8
@export var minimap_margin: int = 20

@onready var maze_generator = get_node("/root/Main/MazeGenerator")
@onready var path_tracker = get_node("/root/Main/PathTracker")
@onready var player = get_node("/root/Main/Player")

var is_visible: bool = false
var minimap_texture: ImageTexture
var minimap_image: Image

func _ready():
	visible = false

	# 等待迷宫生成
	await get_tree().create_timer(0.1).timeout

	if maze_generator:
		create_minimap()

	if path_tracker:
		path_tracker.path_updated.connect(_on_path_updated)

func _input(event):
	if event.is_action_pressed("toggle_minimap"):
		toggle_minimap()

func toggle_minimap():
	is_visible = not is_visible
	visible = is_visible
	if is_visible:
		update_minimap()

func create_minimap():
	var width = maze_generator.maze_width * cell_pixel_size
	var height = maze_generator.maze_height * cell_pixel_size

	minimap_image = Image.create(width, height, false, Image.FORMAT_RGB8)
	minimap_image.fill(Color.BLACK)

	# 绘制迷宫结构
	for y in range(maze_generator.maze_height):
		for x in range(maze_generator.maze_width):
			var cell = maze_generator.maze[y][x]
			var px = x * cell_pixel_size
			var py = y * cell_pixel_size

			# 绘制格子（深灰色表示未访问）
			_fill_rect(minimap_image, px, py, cell_pixel_size, cell_pixel_size, Color(0.2, 0.2, 0.2))

			# 绘制墙壁
			if cell["walls"]["north"]:
				_fill_rect(minimap_image, px, py, cell_pixel_size, 1, Color.WHITE)
			if cell["walls"]["south"]:
				_fill_rect(minimap_image, px, py + cell_pixel_size - 1, cell_pixel_size, 1, Color.WHITE)
			if cell["walls"]["west"]:
				_fill_rect(minimap_image, px, py, 1, cell_pixel_size, Color.WHITE)
			if cell["walls"]["east"]:
				_fill_rect(minimap_image, px + cell_pixel_size - 1, py, 1, cell_pixel_size, Color.WHITE)

	# 标记起点（绿色）
	var start_grid = maze_generator.world_to_grid(maze_generator.start_position)
	_fill_rect(minimap_image, start_grid.x * cell_pixel_size + 2, start_grid.y * cell_pixel_size + 2,
			  cell_pixel_size - 4, cell_pixel_size - 4, Color.GREEN)

	# 标记终点（红色）
	var exit_grid = maze_generator.world_to_grid(maze_generator.exit_position)
	_fill_rect(minimap_image, exit_grid.x * cell_pixel_size + 2, exit_grid.y * cell_pixel_size + 2,
			  cell_pixel_size - 4, cell_pixel_size - 4, Color.RED)

	minimap_texture = ImageTexture.create_from_image(minimap_image)

	# 创建显示节点
	var texture_rect = TextureRect.new()
	texture_rect.name = "MinimapDisplay"
	texture_rect.texture = minimap_texture
	texture_rect.position = Vector2(minimap_margin, minimap_margin)
	texture_rect.size = Vector2(width, height)
	add_child(texture_rect)

	# 添加标题
	var label = Label.new()
	label.text = "地图 (M键开关)"
	label.position = Vector2(minimap_margin, minimap_margin - 25)
	add_child(label)

func update_minimap():
	if not minimap_image or not path_tracker:
		return

	# 重新绘制已访问的路径
	var visited = path_tracker.get_visited_cells()
	for grid_pos in visited.keys():
		var px = grid_pos.x * cell_pixel_size
		var py = grid_pos.y * cell_pixel_size
		# 用浅蓝色标记已访问的格子
		_fill_rect(minimap_image, px + 1, py + 1, cell_pixel_size - 2, cell_pixel_size - 2, Color(0.3, 0.6, 1.0))

	# 重新绘制起点和终点（确保它们不被覆盖）
	var start_grid = maze_generator.world_to_grid(maze_generator.start_position)
	_fill_rect(minimap_image, start_grid.x * cell_pixel_size + 2, start_grid.y * cell_pixel_size + 2,
			  cell_pixel_size - 4, cell_pixel_size - 4, Color.GREEN)

	var exit_grid = maze_generator.world_to_grid(maze_generator.exit_position)
	_fill_rect(minimap_image, exit_grid.x * cell_pixel_size + 2, exit_grid.y * cell_pixel_size + 2,
			  cell_pixel_size - 4, cell_pixel_size - 4, Color.RED)

	# 绘制玩家位置（黄色）
	if player:
		var player_grid = maze_generator.world_to_grid(player.global_position)
		if maze_generator.is_valid_position(player_grid):
			_fill_rect(minimap_image, player_grid.x * cell_pixel_size + 3, player_grid.y * cell_pixel_size + 3,
					  cell_pixel_size - 6, cell_pixel_size - 6, Color.YELLOW)

	minimap_texture.update(minimap_image)

func _on_path_updated(_visited_cells):
	if is_visible:
		update_minimap()

func _fill_rect(image: Image, x: int, y: int, w: int, h: int, color: Color):
	for dy in range(h):
		for dx in range(w):
			var px = x + dx
			var py = y + dy
			if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
				image.set_pixel(px, py, color)

func _process(_delta):
	if is_visible:
		update_minimap()

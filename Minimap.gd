extends Control

# 小地图UI系统 - 全屏显示
@export var cell_pixel_size: int = 20  # 增大单元格尺寸以适应全屏

@onready var maze_generator = get_node("/root/Main/MazeGenerator")
@onready var path_tracker = get_node("/root/Main/PathTracker")
@onready var player = get_node("/root/Main/Player")

var is_visible: bool = false
var minimap_texture: ImageTexture
var minimap_image: Image
var background: ColorRect
var texture_rect: TextureRect
var hint_label: Label

func _ready():
	visible = false

	# 等待迷宫生成
	await get_tree().create_timer(0.1).timeout

	if maze_generator:
		create_minimap()

	if path_tracker:
		path_tracker.path_updated.connect(_on_path_updated)

func _input(event):
	# M键切换小地图开关
	if event.is_action_pressed("toggle_minimap"):
		toggle_minimap()

func toggle_minimap():
	is_visible = not is_visible
	visible = is_visible
	if is_visible:
		update_minimap()

func create_minimap():
	# 设置控件为全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 创建透明黑色背景（不透明度10%）
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.1)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

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

			# 绘制路径（白色表示可走的路）
			_fill_rect(minimap_image, px, py, cell_pixel_size, cell_pixel_size, Color.WHITE)

			# 绘制墙壁（黑色）
			if cell["walls"]["north"]:
				_fill_rect(minimap_image, px, py, cell_pixel_size, 2, Color.BLACK)
			if cell["walls"]["south"]:
				_fill_rect(minimap_image, px, py + cell_pixel_size - 2, cell_pixel_size, 2, Color.BLACK)
			if cell["walls"]["west"]:
				_fill_rect(minimap_image, px, py, 2, cell_pixel_size, Color.BLACK)
			if cell["walls"]["east"]:
				_fill_rect(minimap_image, px + cell_pixel_size - 2, py, 2, cell_pixel_size, Color.BLACK)

	# 标记起点（绿色）
	var start_grid = maze_generator.world_to_grid(maze_generator.start_position)
	_fill_rect(minimap_image, start_grid.x * cell_pixel_size + 4, start_grid.y * cell_pixel_size + 4,
			  cell_pixel_size - 8, cell_pixel_size - 8, Color.GREEN)

	# 标记终点（红色）
	var exit_grid = maze_generator.world_to_grid(maze_generator.exit_position)
	_fill_rect(minimap_image, exit_grid.x * cell_pixel_size + 4, exit_grid.y * cell_pixel_size + 4,
			  cell_pixel_size - 8, cell_pixel_size - 8, Color.RED)

	minimap_texture = ImageTexture.create_from_image(minimap_image)

	# 创建显示节点 - 满版显示
	texture_rect = TextureRect.new()
	texture_rect.name = "MinimapDisplay"
	texture_rect.texture = minimap_texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(texture_rect)

	# 添加提示文字
	hint_label = Label.new()
	hint_label.text = "按 M 键关闭地图"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 24)
	hint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint_label.position = Vector2(-150, 20)
	hint_label.size = Vector2(300, 50)
	add_child(hint_label)

func update_minimap():
	if not minimap_image or not path_tracker:
		return

	# 重新创建图像以清除之前的内容
	var width = maze_generator.maze_width * cell_pixel_size
	var height = maze_generator.maze_height * cell_pixel_size
	minimap_image = Image.create(width, height, false, Image.FORMAT_RGB8)
	minimap_image.fill(Color.BLACK)

	# 重新绘制迷宫结构
	var visited = path_tracker.get_visited_cells()
	for y in range(maze_generator.maze_height):
		for x in range(maze_generator.maze_width):
			var cell = maze_generator.maze[y][x]
			var px = x * cell_pixel_size
			var py = y * cell_pixel_size
			var grid_pos = Vector2i(x, y)

			# 判断是否已访问
			if visited.has(grid_pos):
				# 已访问的路径显示为白色
				_fill_rect(minimap_image, px, py, cell_pixel_size, cell_pixel_size, Color.WHITE)
			else:
				# 未访问的路径显示为深灰色
				_fill_rect(minimap_image, px, py, cell_pixel_size, cell_pixel_size, Color(0.3, 0.3, 0.3))

			# 绘制墙壁（黑色）
			if cell["walls"]["north"]:
				_fill_rect(minimap_image, px, py, cell_pixel_size, 2, Color.BLACK)
			if cell["walls"]["south"]:
				_fill_rect(minimap_image, px, py + cell_pixel_size - 2, cell_pixel_size, 2, Color.BLACK)
			if cell["walls"]["west"]:
				_fill_rect(minimap_image, px, py, 2, cell_pixel_size, Color.BLACK)
			if cell["walls"]["east"]:
				_fill_rect(minimap_image, px + cell_pixel_size - 2, py, 2, cell_pixel_size, Color.BLACK)

	# 重新绘制起点（绿色）
	var start_grid = maze_generator.world_to_grid(maze_generator.start_position)
	_fill_rect(minimap_image, start_grid.x * cell_pixel_size + 4, start_grid.y * cell_pixel_size + 4,
			  cell_pixel_size - 8, cell_pixel_size - 8, Color.GREEN)

	# 重新绘制终点（红色）
	var exit_grid = maze_generator.world_to_grid(maze_generator.exit_position)
	_fill_rect(minimap_image, exit_grid.x * cell_pixel_size + 4, exit_grid.y * cell_pixel_size + 4,
			  cell_pixel_size - 8, cell_pixel_size - 8, Color.RED)

	# 绘制玩家位置（黄色）
	if player:
		var player_grid = maze_generator.world_to_grid(player.global_position)
		if maze_generator.is_valid_position(player_grid):
			_fill_rect(minimap_image, player_grid.x * cell_pixel_size + 6, player_grid.y * cell_pixel_size + 6,
					  cell_pixel_size - 12, cell_pixel_size - 12, Color.YELLOW)

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

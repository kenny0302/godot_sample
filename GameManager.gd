extends Node

# 游戏管理器 - 处理胜利条件等游戏逻辑
@onready var player = get_parent().get_node("Player")
@onready var maze_generator = get_parent().get_node("MazeGenerator")

var game_won: bool = false
var win_ui: Control

func _ready():
	# 等待场景加载
	await get_tree().create_timer(0.2).timeout

	# 查找出口区域
	var exit_area = find_exit_area(maze_generator)
	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_entered)

	create_win_ui()

func find_exit_area(node: Node) -> Area3D:
	if node is Area3D and node.name == "ExitArea":
		return node
	for child in node.get_children():
		var result = find_exit_area(child)
		if result:
			return result
	return null

func _on_exit_area_entered(body):
	if body == player and not game_won:
		game_won = true
		show_win_screen()

func create_win_ui():
	win_ui = Control.new()
	win_ui.name = "WinUI"
	win_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_ui.visible = false
	get_parent().add_child(win_ui)

	# 半透明背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_ui.add_child(bg)

	# 胜利文本
	var win_label = Label.new()
	win_label.text = "恭喜！你成功走出迷宫！\n\n按 ESC 退出"
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_label.set_anchors_preset(Control.PRESET_CENTER)
	win_label.position = Vector2(-200, -50)
	win_label.size = Vector2(400, 100)

	# 设置字体大小
	win_label.add_theme_font_size_override("font_size", 32)

	win_ui.add_child(win_label)

func show_win_screen():
	if win_ui:
		win_ui.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if game_won and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

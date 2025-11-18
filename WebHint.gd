extends Control

# Web平台提示UI
var hint_label: Label
var is_web: bool = false

func _ready():
	is_web = OS.has_feature("web")

	if is_web:
		create_hint_ui()
		# 监听鼠标点击事件
		get_viewport().gui_focus_changed.connect(_on_focus_changed)

func create_hint_ui():
	# 半透明背景
	var bg = ColorRect.new()
	bg.name = "HintBackground"
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 提示文本
	hint_label = Label.new()
	hint_label.text = "点击屏幕开始游戏\n\nClick to Start"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.set_anchors_preset(Control.PRESET_CENTER)
	hint_label.position = Vector2(-200, -50)
	hint_label.size = Vector2(400, 100)
	hint_label.add_theme_font_size_override("font_size", 28)
	add_child(hint_label)

func _input(event):
	if not is_web:
		return

	if event is InputEventMouseButton and event.pressed:
		if visible:
			visible = false

func _on_focus_changed():
	pass

func _process(_delta):
	if not is_web:
		return

	# 检查鼠标是否已被捕获
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if visible:
			visible = false

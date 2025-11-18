extends CharacterBody3D

# 玩家控制器 - 第一人称视角
@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = -9.8

@onready var camera = $Camera3D
@onready var path_tracker = get_node("/root/Main/PathTracker")

var rotation_x: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# 鼠标视角控制
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -PI/2, PI/2)
		camera.rotation.x = rotation_x

	# ESC键释放鼠标
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# 重力
	if not is_on_floor():
		velocity.y += gravity * delta

	# 移动输入
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	# 计算移动方向（相对于玩家朝向）
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

	# 更新路径追踪
	if path_tracker:
		path_tracker.update_player_position(global_position)

extends CharacterBody3D

@export var move_speed: float = 6.0
@export var mouse_sensitivity: float = 0.0025
@export var touch_sensitivity: float = 0.004

@onready var head: Node3D = $Head

var gravity: float = 18.0
var look_touch_id: int = -1
var move_touch_id: int = -1
var move_origin: Vector2 = Vector2.ZERO
var move_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_view(event.relative, mouse_sensitivity)
    elif event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and move_touch_id == -1:
                move_touch_id = event.index
                move_origin = event.position
                move_vector = Vector2.ZERO
            elif look_touch_id == -1:
                look_touch_id = event.index
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                move_vector = Vector2.ZERO
            if event.index == look_touch_id:
                look_touch_id = -1
    elif event is InputEventScreenDrag:
        if event.index == look_touch_id:
            _rotate_view(event.relative, touch_sensitivity)
        elif event.index == move_touch_id:
            move_vector = ((event.position - move_origin) / 75.0).limit_length(1.0)
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _rotate_view(delta: Vector2, sensitivity: float) -> void:
    rotate_y(-delta.x * sensitivity)
    head.rotate_x(-delta.y * sensitivity)
    head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func _physics_process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if move_vector.length() > 0.05:
        input_vector = move_vector
    var direction := (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    move_and_slide()

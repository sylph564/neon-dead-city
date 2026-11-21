extends CharacterBody3D

class TouchOverlay extends Control:
    var joystick_active := false
    var joystick_origin := Vector2.ZERO
    var joystick_value := Vector2.ZERO

    func _draw() -> void:
        if joystick_active:
            draw_circle(joystick_origin, 66.0, Color(0.02, 0.08, 0.13, 0.48))
            draw_arc(joystick_origin, 66.0, 0.0, TAU, 48, Color(0.15, 0.78, 1.0, 0.8), 3.0)
            draw_circle(joystick_origin + joystick_value * 48.0, 25.0, Color(0.12, 0.72, 0.95, 0.78))
            draw_arc(joystick_origin + joystick_value * 48.0, 25.0, 0.0, TAU, 32, Color(0.65, 0.95, 1.0, 0.9), 2.0)

@export var walk_speed: float = 5.2
@export var sprint_speed: float = 8.0
@export var mouse_sensitivity: float = 0.0022
@export var touch_sensitivity: float = 0.0032
@export var jump_velocity: float = 5.2

@onready var head: Node3D = $Head

var gravity: float = 18.0
var look_touch_id: int = -1
var move_touch_id: int = -1
var move_origin: Vector2 = Vector2.ZERO
var move_vector: Vector2 = Vector2.ZERO
var jump_requested := false
var sprint_touch := false
var touch_overlay: TouchOverlay

func _ready() -> void:
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _create_mobile_controls()
    head.get_node("Camera3D").fov = 82.0

func _create_mobile_controls() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MobileControls"
    add_child(layer)

    touch_overlay = TouchOverlay.new()
    touch_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    touch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(touch_overlay)

    var jump_button := Button.new()
    jump_button.text = "JUMP"
    jump_button.position = Vector2(-142, -155)
    jump_button.size = Vector2(112, 76)
    jump_button.anchor_left = 1.0
    jump_button.anchor_top = 1.0
    jump_button.anchor_right = 1.0
    jump_button.anchor_bottom = 1.0
    jump_button.add_theme_font_size_override("font_size", 18)
    jump_button.add_theme_color_override("font_color", Color(0.7, 0.96, 1.0))
    jump_button.modulate = Color(0.55, 0.9, 1.0, 0.88)
    jump_button.pressed.connect(_request_jump)
    layer.add_child(jump_button)

    var sprint_button := Button.new()
    sprint_button.text = "RUN"
    sprint_button.position = Vector2(-142, -245)
    sprint_button.size = Vector2(112, 68)
    sprint_button.anchor_left = 1.0
    sprint_button.anchor_top = 1.0
    sprint_button.anchor_right = 1.0
    sprint_button.anchor_bottom = 1.0
    sprint_button.add_theme_font_size_override("font_size", 17)
    sprint_button.modulate = Color(0.45, 0.85, 1.0, 0.82)
    sprint_button.button_down.connect(func(): sprint_touch = true)
    sprint_button.button_up.connect(func(): sprint_touch = false)
    layer.add_child(sprint_button)

func _request_jump() -> void:
    jump_requested = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_view(event.relative, mouse_sensitivity)
    elif event is InputEventScreenTouch:
        var screen_size := get_viewport().get_visible_rect().size
        if event.pressed:
            if event.position.x < screen_size.x * 0.48 and event.position.y > screen_size.y * 0.38 and move_touch_id == -1:
                move_touch_id = event.index
                move_origin = event.position
                move_vector = Vector2.ZERO
                touch_overlay.joystick_active = true
                touch_overlay.joystick_origin = move_origin
                touch_overlay.joystick_value = Vector2.ZERO
                touch_overlay.queue_redraw()
            elif event.position.x >= screen_size.x * 0.48 and event.position.y < screen_size.y - 270 and look_touch_id == -1:
                look_touch_id = event.index
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                move_vector = Vector2.ZERO
                touch_overlay.joystick_active = false
                touch_overlay.queue_redraw()
            if event.index == look_touch_id:
                look_touch_id = -1
    elif event is InputEventScreenDrag:
        if event.index == look_touch_id:
            _rotate_view(event.relative, touch_sensitivity)
        elif event.index == move_touch_id:
            move_vector = ((event.position - move_origin) / 62.0).limit_length(1.0)
            touch_overlay.joystick_value = move_vector
            touch_overlay.queue_redraw()
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _rotate_view(delta: Vector2, sensitivity: float) -> void:
    rotate_y(-delta.x * sensitivity)
    head.rotate_x(-delta.y * sensitivity)
    head.rotation.x = clamp(head.rotation.x, deg_to_rad(-82), deg_to_rad(82))

func _physics_process(delta: float) -> void:
    var input_vector := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_vector.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_vector.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_vector.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_vector.y += 1.0
    if move_vector.length() > 0.05:
        input_vector = move_vector
    input_vector = input_vector.limit_length(1.0)

    var direction := (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
    var speed := sprint_speed if sprint_touch or Input.is_key_pressed(KEY_SHIFT) else walk_speed
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        if jump_requested or Input.is_key_pressed(KEY_SPACE):
            velocity.y = jump_velocity
        else:
            velocity.y = 0.0
    jump_requested = false
    move_and_slide()

extends CharacterBody3D

class TouchOverlay extends Control:
    var joystick_active := false
    var joystick_origin := Vector2.ZERO
    var joystick_value := Vector2.ZERO

    func _draw() -> void:
        if joystick_active:
            draw_circle(joystick_origin, 66.0, Color(0.015, 0.035, 0.065, 0.62))
            draw_arc(joystick_origin, 66.0, 0.0, TAU, 48, Color(0.12, 0.78, 1.0, 0.9), 3.0)
            draw_circle(joystick_origin + joystick_value * 48.0, 25.0, Color(0.08, 0.62, 0.88, 0.9))
            draw_arc(joystick_origin + joystick_value * 48.0, 25.0, 0.0, TAU, 32, Color(0.72, 0.96, 1.0, 0.95), 2.0)

@export var walk_speed: float = 5.2
@export var sprint_speed: float = 8.0
@export var mouse_sensitivity: float = 0.0022
@export var touch_sensitivity: float = 0.0032
@export var jump_velocity: float = 5.2

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var gravity: float = 18.0
var look_touch_id: int = -1
var move_touch_id: int = -1
var move_origin := Vector2.ZERO
var move_vector := Vector2.ZERO
var jump_requested := false
var sprint_touch := false
var attack_requested := false
var touch_overlay: TouchOverlay
var camera_base_position := Vector3.ZERO
var camera_base_rotation := Vector3.ZERO
var bob_time := 0.0
var jump_bob := 0.0
var punch_time := 0.0
var punch_cooldown := 0.0
var right_arm_pivot: Node3D
var left_arm_pivot: Node3D
var status_label: Label
var health_value := 100.0
var stamina_value := 100.0

func _ready() -> void:
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    camera.fov = 82.0
    camera_base_position = camera.position
    camera_base_rotation = camera.rotation
    _create_view_arms()
    _create_mobile_controls()
    _create_hud()

func _make_material(color: Color, metallic := 0.0, roughness := 0.6, glow := false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 1.4
    return material

func _create_view_arms() -> void:
    var arms_root := Node3D.new()
    arms_root.name = "FirstPersonArms"
    arms_root.position = Vector3.ZERO
    camera.add_child(arms_root)

    var sleeve_mat := _make_material(Color(0.025, 0.045, 0.075), 0.45, 0.42)
    var glove_mat := _make_material(Color(0.012, 0.018, 0.028), 0.25, 0.3)
    var trim_mat := _make_material(Color(0.02, 0.65, 0.95), 0.25, 0.3, true)

    left_arm_pivot = _build_arm(arms_root, "LeftArm", Vector3(-0.34, -0.31, -0.62), sleeve_mat, glove_mat, trim_mat)
    right_arm_pivot = _build_arm(arms_root, "RightArm", Vector3(0.34, -0.31, -0.62), sleeve_mat, glove_mat, trim_mat)

func _build_arm(parent: Node3D, arm_name: String, arm_position: Vector3, sleeve_mat: Material, glove_mat: Material, trim_mat: Material) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = arm_name
    pivot.position = arm_position
    parent.add_child(pivot)

    var sleeve := MeshInstance3D.new()
    var sleeve_mesh := BoxMesh.new()
    sleeve_mesh.size = Vector3(0.19, 0.22, 0.48)
    sleeve.mesh = sleeve_mesh
    sleeve.material_override = sleeve_mat
    sleeve.position = Vector3(0.0, -0.025, 0.12)
    pivot.add_child(sleeve)

    var cuff := MeshInstance3D.new()
    var cuff_mesh := BoxMesh.new()
    cuff_mesh.size = Vector3(0.205, 0.07, 0.09)
    cuff.mesh = cuff_mesh
    cuff.material_override = trim_mat
    cuff.position = Vector3(0.0, -0.025, -0.105)
    pivot.add_child(cuff)

    var fist := MeshInstance3D.new()
    var fist_mesh := SphereMesh.new()
    fist_mesh.radius = 0.105
    fist_mesh.height = 0.19
    fist.mesh = fist_mesh
    fist.material_override = glove_mat
    fist.position = Vector3(0.0, -0.015, -0.19)
    fist.scale = Vector3(1.0, 0.82, 1.25)
    pivot.add_child(fist)
    return pivot

func _create_hud() -> void:
    var layer := get_node_or_null("MobileControls") as CanvasLayer
    if layer == null:
        layer = CanvasLayer.new()
        layer.name = "MobileControls"
        add_child(layer)

    var panel := PanelContainer.new()
    panel.name = "StatusPanel"
    panel.position = Vector2(22, 18)
    panel.custom_minimum_size = Vector2(220, 76)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.008, 0.025, 0.045, 0.78)
    style.border_color = Color(0.05, 0.72, 0.95, 0.9)
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    panel.add_theme_stylebox_override("panel", style)
    layer.add_child(panel)

    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 2)
    panel.add_child(stack)

    var title := Label.new()
    title.text = "N E O N   /   DEAD CITY"
    title.add_theme_font_size_override("font_size", 15)
    title.add_theme_color_override("font_color", Color(0.25, 0.88, 1.0))
    stack.add_child(title)

    status_label = Label.new()
    status_label.text = "HP 100   •   STAMINA 100"
    status_label.add_theme_font_size_override("font_size", 12)
    status_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.95))
    stack.add_child(status_label)

    var hint := Label.new()
    hint.text = "DISTRICT 01  //  NIGHT SHIFT"
    hint.position = Vector2(22, 102)
    hint.add_theme_font_size_override("font_size", 11)
    hint.add_theme_color_override("font_color", Color(0.22, 0.65, 0.78, 0.85))
    layer.add_child(hint)

func _create_mobile_controls() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MobileControls"
    add_child(layer)

    touch_overlay = TouchOverlay.new()
    touch_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    touch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(touch_overlay)

    _add_action_button(layer, "JUMP", Vector2(-118, -112), Vector2(96, 64), _request_jump, Color(0.04, 0.32, 0.48, 0.9))
    _add_action_button(layer, "RUN", Vector2(-118, -190), Vector2(96, 62), _toggle_sprint, Color(0.04, 0.22, 0.34, 0.9))
    _add_action_button(layer, "HIT", Vector2(-226, -112), Vector2(92, 64), _request_attack, Color(0.25, 0.08, 0.16, 0.94))

func _add_action_button(layer: CanvasLayer, caption: String, offset: Vector2, button_size: Vector2, action: Callable, color: Color) -> void:
    var button := Button.new()
    button.text = caption
    button.position = offset
    button.size = button_size
    button.anchor_left = 1.0
    button.anchor_top = 1.0
    button.anchor_right = 1.0
    button.anchor_bottom = 1.0
    button.add_theme_font_size_override("font_size", 16)
    button.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    var normal := StyleBoxFlat.new()
    normal.bg_color = color
    normal.border_color = Color(0.12, 0.78, 1.0, 0.9)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(12)
    button.add_theme_stylebox_override("normal", normal)
    var pressed := normal.duplicate()
    pressed.bg_color = Color(0.08, 0.52, 0.68, 0.98)
    button.add_theme_stylebox_override("pressed", pressed)
    button.pressed.connect(action)
    layer.add_child(button)

func _toggle_sprint() -> void:
    sprint_touch = not sprint_touch

func _request_jump() -> void:
    jump_requested = true

func _request_attack() -> void:
    attack_requested = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_view(event.relative, mouse_sensitivity)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _request_attack()
    elif event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        elif event.keycode == KEY_F or event.keycode == KEY_E:
            _request_attack()
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
    var running := sprint_touch or Input.is_key_pressed(KEY_SHIFT)
    var speed := sprint_speed if running else walk_speed
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        if jump_requested or Input.is_key_pressed(KEY_SPACE):
            velocity.y = jump_velocity
            jump_bob = 1.0
        else:
            velocity.y = 0.0
    jump_requested = false
    move_and_slide()

    var horizontal_speed := Vector2(velocity.x, velocity.z).length()
    if is_on_floor() and horizontal_speed > 0.25:
        bob_time += delta * (13.0 if running else 8.5)
    else:
        bob_time = lerp(bob_time, 0.0, delta * 3.5)
    jump_bob = move_toward(jump_bob, 0.0, delta * 2.4)
    camera.position = camera_base_position + Vector3(0.0, sin(bob_time) * 0.018 * min(horizontal_speed / walk_speed, 1.5) - jump_bob * 0.035, 0.0)
    camera.rotation = camera_base_rotation + Vector3(sin(bob_time * 2.0) * 0.008 * min(horizontal_speed / walk_speed, 1.5), 0.0, cos(bob_time) * 0.012 * min(horizontal_speed / walk_speed, 1.5))

    punch_cooldown = maxf(0.0, punch_cooldown - delta)
    if attack_requested and punch_cooldown <= 0.0:
        _start_punch()
    attack_requested = false
    if punch_time > 0.0:
        punch_time = maxf(0.0, punch_time - delta)
        var t := 1.0 - punch_time / 0.24
        var swing := sin(t * PI)
        right_arm_pivot.rotation = Vector3(-swing * 1.15, swing * 0.12, -swing * 0.08)
        right_arm_pivot.position = Vector3(0.34, -0.31, -0.62 - swing * 0.36)
    else:
        right_arm_pivot.rotation = right_arm_pivot.rotation.lerp(Vector3.ZERO, delta * 18.0)
        right_arm_pivot.position = right_arm_pivot.position.lerp(Vector3(0.34, -0.31, -0.62), delta * 18.0)
    left_arm_pivot.position.y = -0.31 + sin(bob_time) * 0.012

    stamina_value = maxf(0.0, stamina_value - delta * 13.0) if running and horizontal_speed > 0.25 else minf(100.0, stamina_value + delta * 8.0)
    if status_label:
        status_label.text = "HP  %03d    STAMINA  %03d" % [int(health_value), int(stamina_value)]

func _start_punch() -> void:
    punch_time = 0.24
    punch_cooldown = 0.42
    _try_hit_target()

func _try_hit_target() -> void:
    var origin := camera.global_position
    var finish := origin + (-camera.global_transform.basis.z * 2.0)
    var query := PhysicsRayQueryParameters3D.create(origin, finish)
    query.exclude = [get_rid()]
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    if not result.is_empty():
        var target = result.get("collider")
        if target and target.is_in_group("enemies") and target.has_method("take_damage"):
            target.take_damage(10)
